param(
    [string]$Out,
    [int[]]$ScanRow,
    [string]$GameDir = (Resolve-Path "$PSScriptRoot\..\..\.." -ErrorAction SilentlyContinue)
)

$WM_TAKE_SCREENSHOT = 0x8000 + 120

$sig = @'
using System;
using System.Runtime.InteropServices;
public class Shot {
  [DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
}
'@
if (-not ([System.Management.Automation.PSTypeName]'Shot').Type) { Add-Type -TypeDefinition $sig }

$proc = Get-Process | Where-Object { $_.ProcessName -match '^(game|gamemd)$' } | Select-Object -First 1
if (-not $proc) { throw "RA2 is not running" }
if ($proc.MainWindowHandle -eq [IntPtr]::Zero) { throw "RA2 has no main window yet" }

$dir = Join-Path $GameDir "Screenshots"
$mark = (Get-Date).AddMilliseconds(-50)

[void][Shot]::SendMessageW($proc.MainWindowHandle, $WM_TAKE_SCREENSHOT, [IntPtr]::Zero, [IntPtr]::Zero)

$png = $null
for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 100
    $hit = Get-ChildItem "$dir\*.png" -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -ge $mark } |
        Sort-Object LastWriteTime | Select-Object -Last 1
    if ($hit) { $png = $hit.FullName; break }
}
if (-not $png) { throw "no screenshot appeared in $dir (is the forked ddraw.dll deployed?)" }

if ($Out) {
    Copy-Item $png $Out -Force
    $png = (Resolve-Path $Out).Path
}

$png

if ($ScanRow) {
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap $png
    foreach ($y in $ScanRow) {
        $runs = @(); $inRun = $false; $start = 0
        for ($x = 0; $x -lt $bmp.Width; $x++) {
            $c = $bmp.GetPixel($x, $y)
            if ($c.R -gt 110 -and $c.G -lt 75 -and $c.B -lt 75) {
                if (-not $inRun) { $inRun = $true; $start = $x }
            }
            elseif ($inRun) { $inRun = $false; $runs += "$start-$($x-1)" }
        }
        if ($inRun) { $runs += "$start-$($bmp.Width-1)" }
        "row $y red runs: $($runs -join ' ')"
    }
    $bmp.Dispose()
}
