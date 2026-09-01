$scriptDir = Split-Path $PSCommandPath -Parent
$script:overwriteAll = $false

<#
.SYNOPSIS
    Calcola l'hash SHA256 di un file specificato.
.DESCRIPTION
    Verifica se il percorso corrisponde a un file valido e restituisce l'hash SHA256 in formato stringa.
    Se il file non esiste o è una cartella, restituisce $null.
#>
function Get-FileHashMD5 ($filePath) {
    if (Test-Path $filePath -PathType Leaf) {
        return (Get-FileHash -Path $filePath -Algorithm SHA256).Hash
    }
    return $null
}

<#
.SYNOPSIS
    Copia in modo intelligente i file da una sorgente a una destinazione.
.DESCRIPTION
    Itera ricorsivamente su tutti i file presenti in $srcPath. Se un file esiste già nella destinazione:
    - Confronta l'hash SHA256 e lo ignora se identico.
    - Chiede conferma all'utente se l'hash differisce, ripetendo la richiesta finché non viene fornita una risposta valida (S/N/T/A).
    Gestisce la creazione automatica delle cartelle di destinazione mancanti e applica colori distintivi per il tracciamento a schermo.
#>
function Copy-SmartFile ($srcPath, $destDir) {
    $items = Get-ChildItem -Path $srcPath -Recurse -File

    foreach ($item in $items) {
        $relativePath = $item.FullName.Substring($srcPath.Length).TrimStart('\', '/')
        $targetPath = Join-Path $destDir $relativePath
        $targetDir = Split-Path $targetPath -Parent

        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        if (Test-Path $targetPath) {
            $srcHash = Get-FileHashMD5 $item.FullName
            $destHash = Get-FileHashMD5 $targetPath

            if ($srcHash -eq $destHash) {
                Write-Host "[IGNORATO] $relativePath (Hash identico)" -ForegroundColor DarkGray
                continue
            }

            if (-not $script:overwriteAll) {
                Write-Host "`n[CONFLITTO] $relativePath esiste gia con un hash diverso." -ForegroundColor Yellow
                
                $validInput = $false
                $skipFile = $false

                do {
                    $choice = Read-Host "Sovrascrivere? (S)i / (N)o / (T)utti / (A)nnulla"
                    
                    switch ($choice.ToUpper().Trim()) {
                        "S" { 
                            $validInput = $true 
                        }
                        "N" { 
                            Write-Host "[SALTATO] $relativePath" -ForegroundColor Yellow
                            $validInput = $true
                            $skipFile = $true
                        }
                        "T" { 
                            $script:overwriteAll = $true 
                            $validInput = $true
                        }
                        "A" { 
                            Write-Host "[ABORTITO] Ripristino annullato dall'utente." -ForegroundColor Red
                            exit 
                        }
                        Default { 
                            Write-Host "[ERRORE] Opzione non valida. Inserire S, N, T o A." -ForegroundColor Red
                        }
                    }
                } until ($validInput)

                if ($skipFile) {
                    continue
                }
            }
        }

        Copy-Item -Path $item.FullName -Destination $targetPath -Force
        Write-Host "[COPIATO] $relativePath" -ForegroundColor Green
    }
}

# 1. UserProfile ($HOME)
$srcUserProfile = Join-Path $scriptDir "UserProfile"
if (Test-Path $srcUserProfile) {
    Write-Host "`n=== Restore dotfiles in USERPROFILE ===" -ForegroundColor Cyan
    Copy-SmartFile -srcPath $srcUserProfile -destDir $HOME
}

# 2. Documenti
$srcDocuments = Join-Path $scriptDir "MyDocuments"
if (Test-Path $srcDocuments) {
    Write-Host "`n=== Restore dotfiles in DOCUMENTI ===" -ForegroundColor Cyan
    $myDocuments = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments)
    Copy-SmartFile -srcPath $srcDocuments -destDir $myDocuments
}

# 3. AppData (Roaming)
$srcAppData = Join-Path $scriptDir "AppData"
if (Test-Path $srcAppData) {
    Write-Host "`n=== Restore dotfiles in APPDATA ===" -ForegroundColor Cyan
    Copy-SmartFile -srcPath $srcAppData -destDir $env:APPDATA
}

# 4. LocalAppData
$srcLocalAppData = Join-Path $scriptDir "LocalAppData"
if (Test-Path $srcLocalAppData) {
    Write-Host "`n=== Restore dotfiles in LOCALAPPDATA ===" -ForegroundColor Cyan
    Copy-SmartFile -srcPath $srcLocalAppData -destDir $env:LOCALAPPDATA
}

# Pausa finale
$isStandalone = $MyInvocation.ScriptName -eq $PSCommandPath -or $MyInvocation.InvocationName -eq $PSCommandPath
if ($isStandalone) {
    Write-Host ""
    Read-Host "Premere Invio per uscire..."
}