<#
.SYNOPSIS
    Script di backup delle configurazioni CLI (PowerShell, Windows Terminal, ecc.).
.DESCRIPTION
    Crea una cartella di staging con timestamp e la comprime in formato ZIP usando cmdlet nativi.
#>

$Script:StartTime = Get-Date
$ScriptName = Split-Path $PSCommandPath -Leaf
$Host.UI.RawUI.WindowTitle = "${ScriptName}"

# Funzione per verificare ed eseguire la copia con output colorato
function Copy-WithCheck {
    param (
        [string]$Name,
        [string]$Source,
        [string]$Destination,
        [switch]$Recurse
    )

    Write-Host -NoNewline "Copia [$Name]... "

    if (-not (Test-Path -Path $Source)) {
        Write-Host "[NON TROVATO]" -ForegroundColor Yellow
        return
    }

    try {
        if (-not (Test-Path -Path $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }

        $copyParams = @{
            Path        = $Source
            Destination = $Destination
            Force       = $true
            ErrorAction = 'Stop'
        }
        if ($Recurse) { $copyParams['Recurse'] = $true }

        Copy-Item @copyParams
        Write-Host "[OK]" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERRORE: $($_.Exception.Message)]" -ForegroundColor Red
    }
}

# 1. Calcolo del timestamp
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$ZipName = "rubMyCLI-backup.$Timestamp"

# 2. Percorso della cartella Documenti
$MyDocuments = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments)

# Spostamento nella cartella dello script
$ScriptDir = Split-Path $PSCommandPath -Parent
Set-Location $ScriptDir

Write-Host "Creazione cartella di staging..." -ForegroundColor Cyan

$StagingPath = Join-Path $ScriptDir $ZipName
New-Item -ItemType Directory -Path $StagingPath -Force | Out-Null

# Copia i file presenti nella cartella dello script escludendo i file .zip
Get-ChildItem -Path $ScriptDir -File | Where-Object { $_.Extension -ne '.zip' } | Copy-Item -Destination $StagingPath -Force

# Esecuzione copie verificate
Copy-WithCheck -Name "AutoExec.cmd" -Source "$env:APPDATA\AutoExec.cmd" -Destination (Join-Path $StagingPath "AppData")
Copy-WithCheck -Name "bat" -Source "$env:APPDATA\bat\*" -Destination (Join-Path $StagingPath "AppData\bat") -Recurse
Copy-WithCheck -Name "Bottom" -Source "$env:APPDATA\bottom\*" -Destination (Join-Path $StagingPath "AppData\bottom") -Recurse
Copy-WithCheck -Name "Broot" -Source "$env:APPDATA\dystroy\broot\*" -Destination (Join-Path $StagingPath "AppData\dystroy\broot") -Recurse
Copy-WithCheck -Name "Clink" -Source "$env:LOCALAPPDATA\clink\*.lua*" -Destination (Join-Path $StagingPath "LocalAppData\clink")
Copy-WithCheck -Name "FastFetch" -Source "$HOME\.config\fastfetch\*" -Destination (Join-Path $StagingPath "UserProfile\.config\fastfetch") -Recurse
Copy-WithCheck -Name "lsd" -Source "$env:APPDATA\lsd\*" -Destination (Join-Path $StagingPath "AppData\lsd") -Recurse
Copy-WithCheck -Name "Micro" -Source "$HOME\.config\micro\*" -Destination (Join-Path $StagingPath "UserProfile\.config\micro") -Recurse
Copy-WithCheck -Name "Oh My Posh" -Source "$env:APPDATA\oh-my-posh\rb.omp.json" -Destination (Join-Path $StagingPath "AppData\oh-my-posh")
Copy-WithCheck -Name "PowerShell 7" -Source "$MyDocuments\PowerShell\Microsoft.PowerShell_profile.ps1" -Destination (Join-Path $StagingPath "MyDocuments\PowerShell")
Copy-WithCheck -Name "s" -Source "$HOME\.config\s\*" -Destination (Join-Path $StagingPath "UserProfile\.config\s")
Copy-WithCheck -Name "Windows PowerShell" -Source "$MyDocuments\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Destination (Join-Path $StagingPath "MyDocuments\WindowsPowerShell")
Copy-WithCheck -Name "Windows Terminal config" -Source "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Destination (Join-Path $StagingPath "LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState")
Copy-WithCheck -Name "Windows Terminal wallpapers" -Source "$env:APPDATA\WindowsTerminal\*" -Destination (Join-Path $StagingPath "AppData\WindowsTerminal") -Recurse
Copy-WithCheck -Name "WinFetch" -Source "$HOME\.config\winfetch\*" -Destination (Join-Path $StagingPath "UserProfile\.config\winfetch") -Recurse

Write-Host "`nPreparazione pacchetto ZIP e pulizia cartella di staging..." -ForegroundColor Cyan

# Compressione con cmdlet nativo PowerShell
$zipFilePath = "$StagingPath.zip"

try {
    Compress-Archive -Path "$StagingPath\*" -DestinationPath $zipFilePath -CompressionLevel Optimal -ErrorAction Stop
    Write-Host "Archivio ZIP creato con successo: $zipFilePath" -ForegroundColor Green
    
    # Rimozione cartella temporanea di staging
    Remove-Item -Path $StagingPath -Recurse -Force
}
catch {
    Write-Host "[ERRORE COMPRESSIONE]: $($_.Exception.Message)" -ForegroundColor Red
}

$Host.UI.RawUI.WindowTitle = "100% [${ScriptName}]"
Write-Host "`n"
Write-Host " Esecuzione completata. Premere [Invio] per terminare... " -BackgroundColor Blue -ForegroundColor White -NoNewline
Read-Host -AsSecureString | Out-Null