param(
    [Parameter(Mandatory=$true)][string]$ExePath,
    [Parameter(Mandatory=$false)][string]$IcoPath = "",
    [Parameter(Mandatory=$false)][string]$DllPath = ""
)

if (-not (Test-Path $ExePath)) {
    Write-Warning "Target exe does not exist: $ExePath"
    exit 0
}

if (-not $IcoPath -or -not (Test-Path $IcoPath)) {
    $defaultIco = Join-Path $PSScriptRoot "app_icon.ico"
    if (Test-Path $defaultIco) {
        $IcoPath = $defaultIco
    }
}

if (-not $DllPath -or -not (Test-Path $DllPath)) {
    $defaultDll = [System.IO.Path]::ChangeExtension($ExePath, ".dll")
    if (Test-Path $defaultDll) {
        $DllPath = $defaultDll
    }
}

# Resolve version from pubspec.yaml if needed for fallback synthesis
$vMajor = 4
$vMinor = 0
$vPatch = 1
$vBuild = 13
$fileVersionStr = "4.0.1+13"

$dir = $PSScriptRoot
while ($dir -and (Test-Path $dir)) {
    $candidate = Join-Path $dir "pubspec.yaml"
    if (Test-Path $candidate) {
        $content = Get-Content $candidate -Raw
        if ($content -match '(?m)^version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)\+?([0-9]*)') {
            $vMajor = [int]$matches[1]
            $vMinor = [int]$matches[2]
            $vPatch = [int]$matches[3]
            $vBuild = if ($matches[4]) { [int]$matches[4] } else { 0 }
            $buildSuffix = if ($matches[4]) { "+$($matches[4])" } else { "" }
            $fileVersionStr = "$($matches[1]).$($matches[2]).$($matches[3])$buildSuffix"
        }
        break
    }
    $parent = Split-Path $dir -Parent
    if ($parent -eq $dir) { break }
    $dir = $parent
}

$script = @"
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class ResourceUpdater {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr LoadLibraryEx(string lpFileName, IntPtr hFile, uint dwFlags);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr FindResource(IntPtr hModule, IntPtr lpName, IntPtr lpType);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr LoadResource(IntPtr hModule, IntPtr hResInfo);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr LockResource(IntPtr hResData);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint SizeofResource(IntPtr hModule, IntPtr hResInfo);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool FreeLibrary(IntPtr hModule);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr BeginUpdateResource(string pFileName, bool bDeleteExistingResources);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool UpdateResource(IntPtr hUpdate, IntPtr lpType, IntPtr lpName, ushort wLanguage, byte[] lpData, uint cbData);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool EndUpdateResource(IntPtr hUpdate, bool fDiscard);

    private static readonly IntPtr RT_ICON = (IntPtr)3;
    private static readonly IntPtr RT_GROUP_ICON = (IntPtr)14;
    private static readonly IntPtr RT_VERSION = (IntPtr)16;
    private static readonly IntPtr VS_VERSION_INFO = (IntPtr)1;

    private const uint LOAD_LIBRARY_AS_DATAFILE = 0x00000002;
    private const uint LOAD_LIBRARY_AS_IMAGE_RESOURCE = 0x00000020;

    public static bool UpdateAllResources(string exePath, string icoPath, string dllPath, 
                                          string fileVersion, string productVersion,
                                          int vMajor, int vMinor, int vPatch, int vBuild) {
        IntPtr hUpdate = BeginUpdateResource(exePath, false);
        if (hUpdate == IntPtr.Zero) {
            Console.WriteLine("BeginUpdateResource failed with error: " + Marshal.GetLastWin32Error());
            return false;
        }

        bool ok = true;

        // 1. Update Version Info
        byte[] verBytes = null;
        if (!string.IsNullOrEmpty(dllPath) && File.Exists(dllPath)) {
            verBytes = ExtractVersionFromDll(dllPath);
        }

        if (verBytes == null) {
            Console.WriteLine("Generating synthetic PPPlayer version resource...");
            verBytes = CreateVersionResource(fileVersion, productVersion, vMajor, vMinor, vPatch, vBuild);
        }

        if (verBytes != null && verBytes.Length > 0) {
            // Write for US English (1033) and Neutral (0)
            if (!UpdateResource(hUpdate, RT_VERSION, VS_VERSION_INFO, 1033, verBytes, (uint)verBytes.Length)) {
                Console.WriteLine("UpdateResource RT_VERSION 1033 failed: " + Marshal.GetLastWin32Error());
                ok = false;
            }
            UpdateResource(hUpdate, RT_VERSION, VS_VERSION_INFO, 0, verBytes, (uint)verBytes.Length);
        } else {
            Console.WriteLine("Failed to obtain version resource bytes");
            ok = false;
        }

        // 2. Update Icons
        if (!string.IsNullOrEmpty(icoPath) && File.Exists(icoPath)) {
            if (!ApplyIcon(hUpdate, icoPath)) {
                Console.WriteLine("Failed to update icon");
                ok = false;
            }
        }

        if (!ok) {
            EndUpdateResource(hUpdate, true);
            return false;
        }

        return EndUpdateResource(hUpdate, false);
    }

    private static byte[] ExtractVersionFromDll(string dllPath) {
        IntPtr hModule = LoadLibraryEx(dllPath, IntPtr.Zero, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
        if (hModule == IntPtr.Zero) return null;

        IntPtr hResInfo = FindResource(hModule, VS_VERSION_INFO, RT_VERSION);
        if (hResInfo == IntPtr.Zero) {
            FreeLibrary(hModule);
            return null;
        }

        uint size = SizeofResource(hModule, hResInfo);
        IntPtr hResData = LoadResource(hModule, hResInfo);
        if (hResData == IntPtr.Zero) {
            FreeLibrary(hModule);
            return null;
        }

        IntPtr pData = LockResource(hResData);
        if (pData == IntPtr.Zero) {
            FreeLibrary(hModule);
            return null;
        }

        byte[] rawBytes = new byte[size];
        Marshal.Copy(pData, rawBytes, 0, (int)size);
        FreeLibrary(hModule);
        return rawBytes;
    }

    private static bool ApplyIcon(IntPtr hUpdate, string icoPath) {
        byte[] icoBytes = File.ReadAllBytes(icoPath);
        if (icoBytes.Length < 6) return false;

        ushort count = BitConverter.ToUInt16(icoBytes, 4);
        byte[] grpBytes = new byte[6 + count * 14];
        Buffer.BlockCopy(icoBytes, 0, grpBytes, 0, 6);

        for (ushort i = 0; i < count; i++) {
            int dirOffset = 6 + i * 16;
            int grpOffset = 6 + i * 14;

            Buffer.BlockCopy(icoBytes, dirOffset, grpBytes, grpOffset, 12);
            ushort iconId = (ushort)(i + 1);
            byte[] idBytes = BitConverter.GetBytes(iconId);
            grpBytes[grpOffset + 12] = idBytes[0];
            grpBytes[grpOffset + 13] = idBytes[1];

            uint bytesInRes = BitConverter.ToUInt32(icoBytes, dirOffset + 8);
            uint imageOffset = BitConverter.ToUInt32(icoBytes, dirOffset + 12);

            byte[] imgData = new byte[bytesInRes];
            Buffer.BlockCopy(icoBytes, (int)imageOffset, imgData, 0, (int)bytesInRes);

            UpdateResource(hUpdate, RT_ICON, (IntPtr)iconId, 0, imgData, bytesInRes);
            UpdateResource(hUpdate, RT_ICON, (IntPtr)iconId, 1033, imgData, bytesInRes);
        }

        int[] groupIds = new int[] { 101, 1, 32512 };
        foreach (int gid in groupIds) {
            UpdateResource(hUpdate, RT_GROUP_ICON, (IntPtr)gid, 0, grpBytes, (uint)grpBytes.Length);
            UpdateResource(hUpdate, RT_GROUP_ICON, (IntPtr)gid, 1033, grpBytes, (uint)grpBytes.Length);
        }

        return true;
    }

    private static void PadDword(BinaryWriter bw) {
        while (bw.BaseStream.Position % 4 != 0) {
            bw.Write((byte)0);
        }
    }

    private static void WriteStringEntry(BinaryWriter bw, string key, string value) {
        PadDword(bw);
        long startPos = bw.BaseStream.Position;
        bw.Write((ushort)0); // wLength placeholder
        bw.Write((ushort)(value.Length + 1)); // wValueLength in characters
        bw.Write((ushort)1); // wType = 1 (text)
        
        bw.Write(Encoding.Unicode.GetBytes(key + "\0"));
        PadDword(bw);
        bw.Write(Encoding.Unicode.GetBytes(value + "\0"));
        
        long endPos = bw.BaseStream.Position;
        bw.BaseStream.Position = startPos;
        bw.Write((ushort)(endPos - startPos));
        bw.BaseStream.Position = endPos;
    }

    public static byte[] CreateVersionResource(string fileVersion, string productVersion,
                                               int major, int minor, int patch, int build) {
        using (MemoryStream ms = new MemoryStream())
        using (BinaryWriter bw = new BinaryWriter(ms)) {
            // Root VS_VERSIONINFO
            long rootStart = 0;
            bw.Write((ushort)0); // wLength placeholder
            bw.Write((ushort)52); // wValueLength (sizeof VS_FIXEDFILEINFO)
            bw.Write((ushort)0); // wType = 0 (binary)
            bw.Write(Encoding.Unicode.GetBytes("VS_VERSION_INFO\0"));
            PadDword(bw);

            // VS_FIXEDFILEINFO
            bw.Write((uint)0xFEEF04BD); // dwSignature
            bw.Write((uint)0x00010000); // dwStrucVersion
            bw.Write((uint)((major << 16) | minor)); // dwFileVersionMS
            bw.Write((uint)((patch << 16) | build)); // dwFileVersionLS
            bw.Write((uint)((major << 16) | minor)); // dwProductVersionMS
            bw.Write((uint)((patch << 16) | build)); // dwProductVersionLS
            bw.Write((uint)0x3F);       // dwFileFlagsMask
            bw.Write((uint)0x00);       // dwFileFlags
            bw.Write((uint)0x04);       // dwFileOS = VOS__WINDOWS32
            bw.Write((uint)0x01);       // dwFileType = VFT_APP
            bw.Write((uint)0x00);       // dwFileSubtype
            bw.Write((uint)0x00);       // dwFileDateMS
            bw.Write((uint)0x00);       // dwFileDateLS
            PadDword(bw);

            // StringFileInfo
            long sfiStart = bw.BaseStream.Position;
            bw.Write((ushort)0); // wLength placeholder
            bw.Write((ushort)0); // wValueLength
            bw.Write((ushort)1); // wType
            bw.Write(Encoding.Unicode.GetBytes("StringFileInfo\0"));
            PadDword(bw);

            // StringTable "040904e4" (1033, 1252)
            long stStart = bw.BaseStream.Position;
            bw.Write((ushort)0); // wLength placeholder
            bw.Write((ushort)0); // wValueLength
            bw.Write((ushort)1); // wType
            bw.Write(Encoding.Unicode.GetBytes("040904e4\0"));
            PadDword(bw);

            WriteStringEntry(bw, "CompanyName", "com.ppplayer");
            WriteStringEntry(bw, "FileDescription", "PPPlayer");
            WriteStringEntry(bw, "FileVersion", fileVersion);
            WriteStringEntry(bw, "InternalName", "PPPlayer");
            WriteStringEntry(bw, "LegalCopyright", "Copyright (C) 2026 com.ppplayer.app. All rights reserved.");
            WriteStringEntry(bw, "OriginalFilename", "ppplayer.exe");
            WriteStringEntry(bw, "ProductName", "PPPlayer");
            WriteStringEntry(bw, "ProductVersion", productVersion);

            long stEnd = bw.BaseStream.Position;
            bw.BaseStream.Position = stStart;
            bw.Write((ushort)(stEnd - stStart));
            bw.BaseStream.Position = stEnd;

            long sfiEnd = bw.BaseStream.Position;
            bw.BaseStream.Position = sfiStart;
            bw.Write((ushort)(sfiEnd - sfiStart));
            bw.BaseStream.Position = sfiEnd;
            PadDword(bw);

            // VarFileInfo
            long vfiStart = bw.BaseStream.Position;
            bw.Write((ushort)0); // wLength placeholder
            bw.Write((ushort)0); // wValueLength
            bw.Write((ushort)1); // wType
            bw.Write(Encoding.Unicode.GetBytes("VarFileInfo\0"));
            PadDword(bw);

            // Translation Var
            long varStart = bw.BaseStream.Position;
            bw.Write((ushort)0); // wLength placeholder
            bw.Write((ushort)4); // wValueLength: 4 bytes (2x 16-bit integers)
            bw.Write((ushort)0); // wType = 0 (binary)
            bw.Write(Encoding.Unicode.GetBytes("Translation\0"));
            PadDword(bw);
            bw.Write((ushort)0x0409); // language ID (1033)
            bw.Write((ushort)1252);   // code page (1252)

            long varEnd = bw.BaseStream.Position;
            bw.BaseStream.Position = varStart;
            bw.Write((ushort)(varEnd - varStart));
            bw.BaseStream.Position = varEnd;

            long vfiEnd = bw.BaseStream.Position;
            bw.BaseStream.Position = vfiStart;
            bw.Write((ushort)(vfiEnd - vfiStart));
            bw.BaseStream.Position = vfiEnd;

            // Patch root wLength
            long rootEnd = bw.BaseStream.Position;
            bw.BaseStream.Position = rootStart;
            bw.Write((ushort)(rootEnd - rootStart));

            return ms.ToArray();
        }
    }
}
"@

Add-Type -TypeDefinition $script -ErrorAction SilentlyContinue

$resolvedExe = (Resolve-Path $ExePath).Path
$resolvedIco = if ($IcoPath -and (Test-Path $IcoPath)) { (Resolve-Path $IcoPath).Path } else { "" }
$resolvedDll = if ($DllPath -and (Test-Path $DllPath)) { (Resolve-Path $DllPath).Path } else { "" }

$success = [ResourceUpdater]::UpdateAllResources(
    $resolvedExe,
    $resolvedIco,
    $resolvedDll,
    $fileVersionStr,
    $fileVersionStr,
    $vMajor, $vMinor, $vPatch, $vBuild
)

if ($success) {
    Write-Host "Successfully updated PPPlayer metadata and icons for $resolvedExe"
} else {
    Write-Warning "Failed to update resources for $resolvedExe"
    exit 1
}
