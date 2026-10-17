param(
    [Parameter(Mandatory=$true)][string]$ExePath,
    [Parameter(Mandatory=$false)][string]$IcoPath = "",
    [Parameter(Mandatory=$false)][string]$DllPath = ""
)

& "$PSScriptRoot\update_exe_resources.ps1" -ExePath $ExePath -IcoPath $IcoPath -DllPath $DllPath
