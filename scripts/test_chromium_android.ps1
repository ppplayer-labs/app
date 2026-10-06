param(
    [string]$Device = 'emulator-5554',
    [string]$Log = "$PSScriptRoot/../build/validation/chromium-android-live.log"
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path "$PSScriptRoot/..").Path
$logPath = [IO.Path]::GetFullPath($Log)
New-Item -ItemType Directory -Path (Split-Path -Parent $logPath) -Force | Out-Null
[IO.File]::WriteAllText($logPath, '')
$job = Start-Job -ArgumentList $repo, $Device, $logPath -ScriptBlock {
    param($repo, $device, $logPath)
    Set-Location -LiteralPath $repo
    flutter test integration_test/chromium_live_ui_test.dart -d $device --dart-define=PPPLAYER_CHROMIUM=true --dart-define=PPPLAYER_BACKGROUND_PROBE=true --dart-define=PPPLAYER_SOURCE_SWITCH_PROBE=true 2>&1 | ForEach-Object {
        [IO.File]::AppendAllText($logPath, "$_`n")
    }
    $LASTEXITCODE
}
$seen = @{}
$deadline = (Get-Date).AddMinutes(10)
try {
    while ($job.State -eq 'Running' -and (Get-Date) -lt $deadline) {
        if (Test-Path -LiteralPath $logPath) {
            $stream = [IO.File]::Open($logPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
            $reader = [IO.StreamReader]::new($stream)
            try { $content = $reader.ReadToEnd() } finally { $reader.Dispose() }
            foreach ($marker in 'CHROMIUM_BACKGROUND_READY', 'CHROMIUM_SCREEN_OFF_READY', 'CHROMIUM_SCREEN_ON_READY', 'CHROMIUM_MEDIA_PAUSE_READY', 'CHROMIUM_MEDIA_PLAY_READY', 'CHROMIUM_BACKGROUND_DONE') {
                if (!$seen.ContainsKey($marker) -and $content.Contains($marker)) {
                    $seen[$marker] = $true
                    switch ($marker) {
                        'CHROMIUM_BACKGROUND_READY' { adb -s $Device shell input keyevent KEYCODE_HOME }
                        'CHROMIUM_SCREEN_OFF_READY' {
                            adb -s $Device shell input keyevent KEYCODE_SLEEP
                            Start-Sleep -Milliseconds 500
                            $power = adb -s $Device shell dumpsys power
                            $power | Set-Content -LiteralPath "$logPath.screen-off.txt"
                            if (!($power -match 'mWakefulness=(Asleep|Dozing)')) { throw 'Device did not turn its screen off' }
                        }
                        'CHROMIUM_SCREEN_ON_READY' {
                            adb -s $Device shell input keyevent KEYCODE_WAKEUP
                            adb -s $Device shell wm dismiss-keyguard
                        }
                        'CHROMIUM_MEDIA_PAUSE_READY' { adb -s $Device shell cmd media_session dispatch pause }
                        'CHROMIUM_MEDIA_PLAY_READY' { adb -s $Device shell cmd media_session dispatch play }
                        'CHROMIUM_BACKGROUND_DONE' {
                            adb -s $Device shell input keyevent KEYCODE_WAKEUP
                            adb -s $Device shell wm dismiss-keyguard
                            adb -s $Device shell am start -n com.ppplayer.app/.MainActivity
                        }
                    }
                    if ($LASTEXITCODE -ne 0) { throw "Device command failed for $marker" }
                    Write-Output "Handled $marker"
                }
            }
        }
        Start-Sleep -Milliseconds 100
    }
    if ($job.State -eq 'Running') { throw 'Android playback test timed out; inspect the log.' }
    $result = Receive-Job $job -Wait
    if ($job.State -eq 'Failed' -or $result[-1] -ne 0) { throw "Android test failed: $logPath" }
    if ($seen.Count -ne 6) { throw 'Test ended without completing every background/screen-off/media-control phase.' }
    Write-Output "Android background, screen-off, media controls and source switching passed: $logPath"
} finally {
    if ($seen.ContainsKey('CHROMIUM_SCREEN_OFF_READY') -and !$seen.ContainsKey('CHROMIUM_BACKGROUND_DONE')) {
        adb -s $Device shell input keyevent KEYCODE_WAKEUP
        adb -s $Device shell wm dismiss-keyguard
        adb -s $Device shell am start -n com.ppplayer.app/.MainActivity
    }
    if ($job.State -eq 'Running') { Stop-Job $job }
    Remove-Job $job
}
