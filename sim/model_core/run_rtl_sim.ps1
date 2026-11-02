param([Parameter(Mandatory=$true)][string]$VivadoBin)
$ErrorActionPreference = 'Stop'
$base = $PSScriptRoot
python (Join-Path $base 'run_checks.py')
if ($LASTEXITCODE -ne 0) { throw 'Python reference check failed' }
$previous = Get-Location
try {
    Set-Location (Join-Path $base 'simulation')
    $names = @('dpd_top.sv','expcnn.sv','linear_layer_0.sv','cnn0_1d.v',
               'nonlinear_layer.sv','nl_core.v','cordic_abs.v','cordic_exp.v','linear_layer_1.sv')
    $sources = @($names | ForEach-Object { Join-Path $base ('input/rtl/dpd_ip_v1/' + $_) })
    & (Join-Path $VivadoBin 'xvlog.bat') --sv @sources (Join-Path $base 'tb_model_check.sv')
    if ($LASTEXITCODE -ne 0) { throw 'xvlog failed' }
    & (Join-Path $VivadoBin 'xelab.bat') work.tb_model_check -s model_check_snapshot --debug typical --timescale 1ns/1ps -R
    if ($LASTEXITCODE -ne 0) { throw 'xelab / simulation failed' }
    python (Join-Path $base 'check_rtl_trace.py')
    if ($LASTEXITCODE -ne 0) { throw 'RTL trace differs from Python reference' }
} finally { Set-Location $previous }
