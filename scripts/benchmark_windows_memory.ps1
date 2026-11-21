param(
  [ValidateSet('production', 'scenarios')]
  [string]$Mode = 'production',
  [string]$ExePath = '',
  [int]$StressCycles = 10,
  [string]$OutputJson = '',
  [string]$OutputCsv = ''
)

$ErrorActionPreference = 'Stop'
$appRoot = Split-Path -Parent $PSScriptRoot
if (-not $ExePath) {
  $ExePath = Join-Path $appRoot 'build\windows\x64\runner\Release\ppplayer.exe'
}
if (-not (Test-Path $ExePath)) {
  throw "Executable not found: $ExePath. Run 'flutter build windows --release' first."
}
$workDir = Split-Path -Parent $ExePath

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class BenchWin32 {
  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

  public static List<IntPtr> GetTopWindows(uint targetPid) {
    var result = new List<IntPtr>();
    EnumWindows((h, p) => {
      uint pid;
      GetWindowThreadProcessId(h, out pid);
      if (pid == targetPid && IsWindowVisible(h)) {
        result.Add(h);
      }
      return true;
    }, IntPtr.Zero);
    return result;
  }

  public static int Minimize(uint targetPid) {
    var wins = GetTopWindows(targetPid);
    foreach (var h in wins) ShowWindow(h, 6); // SW_MINIMIZE
    return wins.Count;
  }

  public static int Restore(uint targetPid) {
    int count = 0;
    EnumWindows((h, p) => {
      uint pid;
      GetWindowThreadProcessId(h, out pid);
      if (pid == targetPid) {
        ShowWindow(h, 9); // SW_RESTORE
        count++;
      }
      return true;
    }, IntPtr.Zero);
    return count;
  }

  public static int Close(uint targetPid) {
    var wins = GetTopWindows(targetPid);
    foreach (var h in wins) PostMessage(h, 0x0010, IntPtr.Zero, IntPtr.Zero); // WM_CLOSE
    return wins.Count;
  }
}
'@

function Get-GpuMemoryMb([int]$PidVal) {
  try {
    $counters = Get-Counter "\GPU Process Memory(*pid_${PidVal}_*)\Shared Usage", "\GPU Process Memory(*pid_${PidVal}_*)\Local Usage" -ErrorAction Stop
    $shared = 0.0; $local = 0.0
    foreach ($s in $counters.CounterSamples) {
      if ($s.Path -like '*shared usage*') { $shared += $s.CookedValue }
      elseif ($s.Path -like '*local usage*') { $local += $s.CookedValue }
    }
    return [ordered]@{
      gpuSharedMb = [math]::Round($shared / 1MB, 1)
      gpuLocalMb  = [math]::Round($local / 1MB, 1)
    }
  } catch {
    return [ordered]@{ gpuSharedMb = 0.0; gpuLocalMb = 0.0 }
  }
}

function Get-ProcessTreeSnapshot([int]$RootPid) {
  $all = @(Get-CimInstance Win32_Process -Filter "Name = 'ppplayer.exe'" -ErrorAction SilentlyContinue)
  $byParent = @{}
  foreach ($p in $all) {
    $ppid = [int]$p.ParentProcessId
    if (-not $byParent.ContainsKey($ppid)) { $byParent[$ppid] = @() }
    $byParent[$ppid] += $p
  }
  $tree = @()
  $q = [System.Collections.Queue]::new()
  $q.Enqueue($RootPid)
  $seen = @{}
  while ($q.Count -gt 0) {
    $cur = $q.Dequeue()
    if ($seen.ContainsKey($cur)) { continue }
    $seen[$cur] = $true
    $item = $all | Where-Object { [int]$_.ProcessId -eq $cur } | Select-Object -First 1
    if ($item) { $tree += $item }
    if ($byParent.ContainsKey($cur)) {
      foreach ($ch in $byParent[$cur]) { $q.Enqueue([int]$ch.ProcessId) }
    }
  }

  $procs = @()
  $mainWs = 0.0; $mainPriv = 0.0; $mainCpu = 0.0; $mainHandles = 0; $mainThreads = 0
  $treeWs = 0.0; $treePriv = 0.0; $treeCpu = 0.0
  $cefCount = 0

  foreach ($c in ($tree | Sort-Object WorkingSetSize -Descending)) {
    $gp = Get-Process -Id $c.ProcessId -ErrorAction SilentlyContinue
    $ws = [math]::Round($c.WorkingSetSize / 1MB, 1)
    $priv = [math]::Round($c.PrivatePageCount / 1MB, 1)
    $cpu = if ($gp) { [math]::Round($gp.TotalProcessorTime.TotalSeconds, 3) } else { 0.0 }
    $role = 'main'
    if ($c.CommandLine -match '--type=([^\s]+)') {
      $role = $Matches[1]
      if ($c.CommandLine -match '--utility-sub-type=([^\s]+)') {
        $role = "$role ($($Matches[1]))"
      }
      $cefCount++
    }
    $treeWs += $ws
    $treePriv += $priv
    $treeCpu += $cpu
    if ([int]$c.ProcessId -eq $RootPid) {
      $mainWs = $ws; $mainPriv = $priv; $mainCpu = $cpu
      if ($gp) { $mainHandles = $gp.HandleCount; $mainThreads = $gp.Threads.Count }
    }
    $procs += [ordered]@{
      pid = [int]$c.ProcessId
      ppid = [int]$c.ParentProcessId
      role = $role
      workingSetMb = $ws
      privateMb = $priv
      cpuSeconds = $cpu
    }
  }

  $gpu = Get-GpuMemoryMb -PidVal $RootPid
  return [ordered]@{
    timestampUtc = [DateTime]::UtcNow.ToString('o')
    mainWorkingSetMb = [math]::Round($mainWs, 1)
    mainPrivateMb = [math]::Round($mainPriv, 1)
    treeWorkingSetMb = [math]::Round($treeWs, 1)
    treePrivateMb = [math]::Round($treePriv, 1)
    mainGpuSharedMb = $gpu.gpuSharedMb
    mainGpuLocalMb = $gpu.gpuLocalMb
    processCount = $procs.Count
    cefSubprocessCount = $cefCount
    mainCpuSeconds = [math]::Round($mainCpu, 3)
    treeCpuSeconds = [math]::Round($treeCpu, 3)
    mainHandles = $mainHandles
    mainThreads = $mainThreads
    processes = $procs
  }
}

$logDir = Join-Path $env:TEMP 'ppplayer_bench'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$stdoutFile = Join-Path $logDir "stdout_$Mode.log"
$stderrFile = Join-Path $logDir "stderr_$Mode.log"
Remove-Item $stdoutFile, $stderrFile -ErrorAction SilentlyContinue

$logicalCores = [Environment]::ProcessorCount
$scenarios = @()
$peakTreeWs = 0.0
$peakTreePriv = 0.0
$peakMainWs = 0.0
$peakMainPriv = 0.0

function Record-Stage([string]$Name, [int]$RootPid, [int]$SampleSeconds = 4, [hashtable]$Extra = @{}) {
  $before = Get-ProcessTreeSnapshot -RootPid $RootPid
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  Start-Sleep -Seconds $SampleSeconds
  $after = Get-ProcessTreeSnapshot -RootPid $RootPid
  $elapsed = $sw.Elapsed.TotalSeconds

  $mainCpuDelta = [math]::Max(0.0, $after.mainCpuSeconds - $before.mainCpuSeconds)
  $treeCpuDelta = [math]::Max(0.0, $after.treeCpuSeconds - $before.treeCpuSeconds)
  $mainCpuPct = [math]::Round((($mainCpuDelta / $elapsed) / $logicalCores) * 100.0, 2)
  $treeCpuPct = [math]::Round((($treeCpuDelta / $elapsed) / $logicalCores) * 100.0, 2)

  if ($after.treeWorkingSetMb -gt $script:peakTreeWs) { $script:peakTreeWs = $after.treeWorkingSetMb }
  if ($after.treePrivateMb -gt $script:peakTreePriv) { $script:peakTreePriv = $after.treePrivateMb }
  if ($after.mainWorkingSetMb -gt $script:peakMainWs) { $script:peakMainWs = $after.mainWorkingSetMb }
  if ($after.mainPrivateMb -gt $script:peakMainPriv) { $script:peakMainPriv = $after.mainPrivateMb }

  $entry = [ordered]@{
    scenario = $Name
    mainWorkingSetMb = $after.mainWorkingSetMb
    mainPrivateMb = $after.mainPrivateMb
    treeWorkingSetMb = $after.treeWorkingSetMb
    treePrivateMb = $after.treePrivateMb
    mainGpuSharedMb = $after.mainGpuSharedMb
    processCount = $after.processCount
    cefSubprocessCount = $after.cefSubprocessCount
    mainCpuSystemPct = $mainCpuPct
    treeCpuSystemPct = $treeCpuPct
    mainHandles = $after.mainHandles
    mainThreads = $after.mainThreads
    processes = $after.processes
  }
  foreach ($k in $Extra.Keys) { $entry[$k] = $Extra[$k] }
  $script:scenarios += $entry
  Write-Host ("[{0,-22}] MainWS={1,6}MB MainPriv={2,6}MB TreeWS={3,6}MB TreePriv={4,6}MB GPU={5,5}MB Procs={6} CPU={7,5}%" -f `
    $Name, $entry.mainWorkingSetMb, $entry.mainPrivateMb, $entry.treeWorkingSetMb, $entry.treePrivateMb, $entry.mainGpuSharedMb, $entry.processCount, $entry.treeCpuSystemPct)
}

if ($Mode -eq 'production') {
  $proc = Start-Process -FilePath $ExePath -WorkingDirectory $workDir `
    -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile -PassThru
  $rootPid = $proc.Id

  Start-Sleep -Seconds 2
  Record-Stage -Name 'startup_t2s' -RootPid $rootPid -SampleSeconds 2
  Start-Sleep -Seconds 4
  Record-Stage -Name 'idle_steady' -RootPid $rootPid -SampleSeconds 5

  [BenchWin32]::Minimize([uint32]$rootPid) | Out-Null
  Start-Sleep -Seconds 2
  Record-Stage -Name 'minimized' -RootPid $rootPid -SampleSeconds 4

  [BenchWin32]::Restore([uint32]$rootPid) | Out-Null
  Start-Sleep -Seconds 2
  Record-Stage -Name 'restored' -RootPid $rootPid -SampleSeconds 3

  $closeSw = [System.Diagnostics.Stopwatch]::StartNew()
  [BenchWin32]::Close([uint32]$rootPid) | Out-Null
  $cleanExit = $proc.WaitForExit(15000)
  $shutdownMs = [math]::Round($closeSw.Elapsed.TotalMilliseconds, 1)
  if (-not $cleanExit) { Stop-Process -Id $rootPid -Force -ErrorAction SilentlyContinue }
} else {
  $argList = @("--bench-stress-cycles=$StressCycles")
  $proc = Start-Process -FilePath $ExePath -WorkingDirectory $workDir -ArgumentList $argList `
    -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile -PassThru
  $rootPid = $proc.Id

  $seenStages = @{}
  $deadline = [DateTime]::UtcNow.AddMinutes(5)
  while (-not $proc.HasExited -and [DateTime]::UtcNow -lt $deadline) {
    Start-Sleep -Milliseconds 250
    if (Test-Path $stdoutFile) {
      $lines = @(Get-Content -LiteralPath $stdoutFile -ErrorAction SilentlyContinue)
      foreach ($line in $lines) {
        if ($line -match '^\[BENCH_READY\]\s+(\S+)(.*)$') {
          $stage = $Matches[1]
          $rest = $Matches[2].Trim()
          if (-not $seenStages.ContainsKey($stage)) {
            $seenStages[$stage] = $true
            if ($stage -eq 'minimized') {
              [BenchWin32]::Minimize([uint32]$rootPid) | Out-Null
              Start-Sleep -Seconds 2
              Record-Stage -Name $stage -RootPid $rootPid -SampleSeconds 4 -Extra @{ detail = $rest }
              [BenchWin32]::Restore([uint32]$rootPid) | Out-Null
            } else {
              $sampleSec = if ($stage -eq 'startup') { 1 } else { 3 }
              Record-Stage -Name $stage -RootPid $rootPid -SampleSeconds $sampleSec -Extra @{ detail = $rest }
            }
            # Signal benchmark app to advance by writing ack file
            Set-Content -LiteralPath (Join-Path $logDir "ack_$stage.txt") -Value 'ok'
          }
        }
      }
      if ($lines -match '^\[BENCH_DONE\]') { break }
    }
  }

  $closeSw = [System.Diagnostics.Stopwatch]::StartNew()
  [BenchWin32]::Close([uint32]$rootPid) | Out-Null
  $cleanExit = $proc.WaitForExit(15000)
  $shutdownMs = [math]::Round($closeSw.Elapsed.TotalMilliseconds, 1)
  if (-not $cleanExit) { Stop-Process -Id $rootPid -Force -ErrorAction SilentlyContinue }
}

Start-Sleep -Seconds 2
$orphans = @(Get-CimInstance Win32_Process -Filter "Name = 'ppplayer.exe'" -ErrorAction SilentlyContinue).Count

$result = [ordered]@{
  mode = $Mode
  exePath = $ExePath
  logicalProcessors = $logicalCores
  timestampUtc = [DateTime]::UtcNow.ToString('o')
  peakMainWorkingSetMb = $peakMainWs
  peakMainPrivateMb = $peakMainPriv
  peakTreeWorkingSetMb = $peakTreeWs
  peakTreePrivateMb = $peakTreePriv
  cleanExit = $cleanExit
  shutdownMs = $shutdownMs
  orphanProcesses = $orphans
  scenarios = $scenarios
}

if ($OutputJson) {
  $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputJson -Encoding UTF8
}
if ($OutputCsv) {
  $scenarios | ForEach-Object {
    [PSCustomObject]@{
      scenario = $_.scenario
      mainWorkingSetMb = $_.mainWorkingSetMb
      mainPrivateMb = $_.mainPrivateMb
      treeWorkingSetMb = $_.treeWorkingSetMb
      treePrivateMb = $_.treePrivateMb
      mainGpuSharedMb = $_.mainGpuSharedMb
      processCount = $_.processCount
      cefSubprocessCount = $_.cefSubprocessCount
      mainCpuSystemPct = $_.mainCpuSystemPct
      treeCpuSystemPct = $_.treeCpuSystemPct
      mainHandles = $_.mainHandles
      mainThreads = $_.mainThreads
    }
  } | Export-Csv -LiteralPath $OutputCsv -NoTypeInformation -Encoding UTF8
}

Write-Host "`n=== SUMMARY ==="
Write-Host ("Peak Tree WS={0} MB | Peak Tree Priv={1} MB | Peak Main WS={2} MB | CleanExit={3} ({4}ms) | Orphans={5}" -f `
  $peakTreeWs, $peakTreePriv, $peakMainWs, $cleanExit, $shutdownMs, $orphans)
