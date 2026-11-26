# Праверка падпісанага выпуску — тая самая, што будзе рабіць аўтаабнаўленне плагіна ў карыстальніка:
#   1) подпіс latest.json правяраецца публічным ключом (ECDSA P-256 + SHA-256, сродкамі Windows);
#   2) памер і SHA-256 файла плагіна (пасля раскадавання base64) супадаюць з latest.json.
# Запуск: powershell -NoProfile -ExecutionPolicy Bypass -File verify_release.ps1 -Dir <папка> -PublicKey <base64>
param([Parameter(Mandatory = $true)][string]$Dir, [Parameter(Mandatory = $true)][string]$PublicKey)
$ErrorActionPreference = 'Stop'
try {
    $xy = [Convert]::FromBase64String($PublicKey.Trim())
    if ($xy.Length -ne 64) { throw 'public key: expected 64 bytes' }
    # BCRYPT_ECCKEY_BLOB: 'ECS1' (ECDSA_PUBLIC_P256_MAGIC), даўжыня 32, затым X і Y
    [byte[]]$blob = @(0x45, 0x43, 0x53, 0x31, 0x20, 0, 0, 0) + $xy
    $key = [System.Security.Cryptography.CngKey]::Import($blob, [System.Security.Cryptography.CngKeyBlobFormat]::EccPublicBlob)
    $ec = New-Object System.Security.Cryptography.ECDsaCng($key)
    $ec.HashAlgorithm = [System.Security.Cryptography.CngAlgorithm]::Sha256
    $data = [IO.File]::ReadAllBytes((Join-Path $Dir 'latest.json'))
    $sig = [Convert]::FromBase64String(([IO.File]::ReadAllText((Join-Path $Dir 'latest.json.sig'))).Trim())
    if (-not $ec.VerifyData($data, $sig)) { Write-Output 'FAIL signature'; exit 2 }
    $j = [Text.Encoding]::UTF8.GetString($data) | ConvertFrom-Json
    $name = Split-Path $j.star.url -Leaf
    $f = Join-Path $Dir $name
    $bytes = [IO.File]::ReadAllBytes($f)
    if ($j.star.encoding -eq 'base64') { $bytes = [Convert]::FromBase64String([Text.Encoding]::ASCII.GetString($bytes)) }
    if ($bytes.Length -ne [int64]$j.star.size) { Write-Output ("FAIL size " + $bytes.Length); exit 3 }
    $sha = [Security.Cryptography.SHA256]::Create()
    $h = (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join '')
    if ($h -ne $j.star.sha256) { Write-Output "FAIL sha256 $h"; exit 4 }
    Write-Output ("OK " + $j.version)
    exit 0
} catch {
    Write-Output ("FAIL " + $_.Exception.Message)
    exit 5
}
