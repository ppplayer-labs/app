param(
    [string]$Device = 'emulator-5554',
    [string]$Log = "$PSScriptRoot/../build/validation/native-android-release.log",
    [switch]$NoBuild
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path "$PSScriptRoot/..").Path
$logPath = [IO.Path]::GetFullPath($Log)
$artifactDir = "$repo/build/validation"
$apk = "$artifactDir/native-release-probe.apk"
New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null

function Convert-ToWslPath([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if ($full -notmatch '^[A-Za-z]:\\') { throw 'WSL verification requires an absolute drive path' }
    '/mnt/' + $full.Substring(0, 1).ToLowerInvariant() + $full.Substring(2).Replace('\', '/')
}

function Save-DeviceScreenshot([string]$Destination) {
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = (Get-Command adb).Source
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    foreach ($argument in @('-s', $Device, 'exec-out', 'screencap', '-p')) {
        $start.ArgumentList.Add($argument)
    }
    $capture = [Diagnostics.Process]::Start($start)
    $output = [IO.File]::Create($Destination)
    try {
        $capture.StandardOutput.BaseStream.CopyTo($output)
        $capture.WaitForExit()
        if ($capture.ExitCode -ne 0) { throw 'Device screenshot failed' }
    } finally { $output.Dispose(); $capture.Dispose() }
}

Push-Location -LiteralPath $repo
$collector = $null
try {
    if (!$NoBuild) {
        $previousApk = "$repo/build/app/outputs/flutter-apk/app-release.apk"
        if ((Test-Path -LiteralPath $previousApk) -and !(Test-Path -LiteralPath "$artifactDir/app-release-before-probe.apk")) {
            Copy-Item -LiteralPath $previousApk -Destination "$artifactDir/app-release-before-probe.apk"
        }
        flutter build apk --release --target-platform android-arm64,android-x64 --target tool/native_release_probe.dart *> "$logPath.build.txt"
        if ($LASTEXITCODE -ne 0) { throw "Release probe build failed: $logPath.build.txt" }
        Copy-Item -LiteralPath "$repo/build/app/outputs/flutter-apk/app-release.apk" -Destination $apk
    }
    $configurationPath = "$repo/.dart_tool/package_config.json"
    $configuration = Get-Content -Raw -LiteralPath $configurationPath | ConvertFrom-Json
    $nativePackage = $configuration.packages | Where-Object { $_.name -eq 'flutter_media_kit' }
    if (!$nativePackage) { throw 'Resolved flutter_media_kit package is missing; run flutter pub get first' }
    $configurationUri = [Uri]::new([IO.Path]::GetFullPath($configurationPath))
    $packageRoot = [Uri]::new($configurationUri, [string]$nativePackage.rootUri).LocalPath
    $packageLinux = Convert-ToWslPath $packageRoot
    $verifier = Convert-ToWslPath "$repo/tool/verify_native_apk.py"
    $apkLinux = Convert-ToWslPath $apk
    wsl -d Ubuntu -- python3 $verifier $apkLinux --package $packageLinux *> "$logPath.artifacts.txt"
    if ($LASTEXITCODE -ne 0) { throw "Release native artifact verification failed: $logPath.artifacts.txt" }
    adb -s $Device install -r $apk *> "$logPath.install.txt"
    if ($LASTEXITCODE -ne 0) { throw 'Release probe installation failed' }
    adb -s $Device shell am force-stop com.ppplayer.app
    if ($LASTEXITCODE -ne 0) { throw 'Could not stop previous test app' }
    $collector = Start-Process -FilePath (Get-Command adb).Source -ArgumentList @(
        '-s', $Device, 'logcat', '-v', 'brief', '-T', '1', 'flutter:I', 'AndroidRuntime:E', 'libc:F', '*:S'
    ) -WindowStyle Hidden -RedirectStandardOutput $logPath -RedirectStandardError "$logPath.collector.txt" -PassThru
    adb -s $Device shell am start -W -n com.ppplayer.app/.MainActivity *> "$logPath.launch.txt"
    if ($LASTEXITCODE -ne 0) { throw 'Release probe launch failed' }
    $deadline = (Get-Date).AddMinutes(3)
    $screenshotTaken = $false
    while ((Get-Date) -lt $deadline) {
        $stream = [IO.File]::Open($logPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        $reader = [IO.StreamReader]::new($stream)
        try { $content = $reader.ReadToEnd() } finally { $reader.Dispose() }
        $begin = $content.IndexOf('NATIVE_RELEASE_BEGIN mode=release')
        if ($begin -ge 0) {
            $run = $content.Substring($begin)
            if ($run.Contains('NATIVE_RELEASE_FAIL') -or $run.Contains('FATAL EXCEPTION') -or $run.Contains('Fatal signal')) {
                throw "Release playback probe failed: $logPath"
            }
            if (!$screenshotTaken -and $run.Contains('NATIVE_RELEASE_VIDEO_READY round=1')) {
                Save-DeviceScreenshot "$logPath.video.png"
                $screenshotTaken = $true
            }
            if ($run.Contains('NATIVE_RELEASE_PASS rounds=3')) {
                foreach ($round in 1..3) {
                    if (!$run.Contains("NATIVE_RELEASE_ROUND_PASS round=$round")) { throw "Missing playback round $round" }
                }
                if ($run.Contains('Failed to create file cache')) { throw 'Android disk cache still fails' }
                Write-Output "Release native video playback, pause, seek, resume and three surface cycles passed: $logPath"
                return
            }
        }
        if ($collector.HasExited) { throw 'Device log collector exited before test completion' }
        Start-Sleep -Milliseconds 100
    }
    throw "Release playback probe timed out: $logPath"
} finally {
    if ($collector -and !$collector.HasExited) { Stop-Process -Id $collector.Id }
    adb -s $Device shell am force-stop com.ppplayer.app
    Pop-Location
}
