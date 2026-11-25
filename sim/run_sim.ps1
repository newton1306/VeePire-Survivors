param(
    [string]$Testbench = "tb_v8_mouse_quiz",
    [string]$VivadoBin = "D:\Vivado\2024.2\bin"
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$SimWork  = Join-Path $RepoRoot "sim_work"
New-Item -ItemType Directory -Force -Path $SimWork | Out-Null

# Stage BRAM .mem files into sim_work/ so $readmemh("*.mem") resolves cleanly
Copy-Item -Force (Join-Path $RepoRoot "mem\*.mem") $SimWork

$xvlog = if (Get-Command xvlog -ErrorAction SilentlyContinue) { "xvlog" } else { Join-Path $VivadoBin "xvlog.bat" }
$xelab = if (Get-Command xelab -ErrorAction SilentlyContinue) { "xelab" } else { Join-Path $VivadoBin "xelab.bat" }
$xsim  = if (Get-Command xsim  -ErrorAction SilentlyContinue) { "xsim"  } else { Join-Path $VivadoBin "xsim.bat"  }

if (-not (Get-Command $xvlog -ErrorAction SilentlyContinue)) {
    throw "xvlog not found. Pass -VivadoBin or add Vivado bin to PATH."
}

$rtlFiles = Get-ChildItem (Join-Path $RepoRoot "rtl\*.v") | Sort-Object Name | ForEach-Object { $_.FullName }
$tbPath   = Join-Path $RepoRoot "sim\$Testbench.v"
if (-not (Test-Path $tbPath)) {
    throw "Testbench not found: $tbPath"
}

Push-Location $SimWork
try {
    & $xvlog -i (Join-Path $RepoRoot "rtl") @rtlFiles $tbPath
    if ($LASTEXITCODE -ne 0) { throw "xvlog failed ($LASTEXITCODE)" }

    & $xelab $Testbench -s "${Testbench}_snap" -timescale 1ns/1ps
    if ($LASTEXITCODE -ne 0) { throw "xelab failed ($LASTEXITCODE)" }

    & $xsim "${Testbench}_snap" -runall
    if ($LASTEXITCODE -ne 0) { throw "xsim failed ($LASTEXITCODE)" }
} finally {
    Pop-Location
}
