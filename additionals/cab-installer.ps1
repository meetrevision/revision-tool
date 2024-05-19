param (   
    [Parameter(Mandatory = $true)]
    [string]$Path
)

if (!(Test-Path -Path $Path)) {
    Write-Host "$Path not found"
    Exit 1
}

$certRegPath = "HKLM:\Software\Microsoft\SystemCertificates\ROOT\Certificates"
$cabPaths = @(Get-ChildItem -Path $Path -File -Filter "*.cab" -Recurse -Force | Select-Object -ExpandProperty FullName)


if ($cabPaths.Count -eq 0) {
    Write-Host "No CAB files found in $Path"
    Exit 1
}

foreach ($cabPath in $cabPaths) {
    $cert = (Get-AuthenticodeSignature $cabPath).SignerCertificate
    $certPath = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllBytes($certPath, $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
    Import-Certificate $certPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null
    Copy-Item -Path "$certRegPath\$($cert.Thumbprint)" "$certRegPath\8A334AA8052DD244A647306A76B8178FA215F344" -Force | Out-Null
    Add-WindowsPackage -Online -NoRestart -IgnoreCheck -PackagePath $cabPath
    Get-ChildItem "Cert:\LocalMachine\Root\$($cert.Thumbprint)" | Remove-Item -Force | Out-Null
    Remove-Item "$certRegPath\8A334AA8052DD244A647306A76B8178FA215F344" -Force -Recurse | Out-Null
}