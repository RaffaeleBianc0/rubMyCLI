<#
TODO:
    - Translate all the function names and comments in English.
    - Enhance this comments section with appropriate items.
    - Enhance the progress output with any relevant stuff you think it would be useful.
=============================================================================
.SYNOPSIS
    Personalizza la CLI (interfaccia a linea di comando) di Windows,
    sia PowerShell sia CMD, eseguendo queste attività:
    - Installazione scoop package manager.
    - Installazione Windows Terminal (se necessario).
    - Installazione ultima versione di PowerShell.
    - Installazione font + icone per CLI.
    - Installazione Moduli PowerShell ed Applicazioni varie per CLI.
    - Configura Windows Terminal + $PROFILE PowerShell + tutte le app CLI.
.NOTES
    - Se all'avvio di questo script compare l'errore 
        "[...] cannot be loaded because running scripts is disabled on this system",
      allora:
        1. Aprire un prompt PowerShell eseguito come Amministratore
        2. Eseguire questo comando:
            Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
=============================================================================
#>

#Region Funzioni
function AggiornaProgressbar {
    <#
    .SYNOPSIS
        Aggiornamento Progressbar con ETA (Estimated Time of Arrival) e layout a larghezza fissa.
    .DESCRIPTION
        Progressbar avanzata con supporto per stili PS5, PS7 e Inline su riga di comando.
        Consente di specificare $MaxTextLength per mantenere fisso il campo del testo/descrizione.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [int] $PassNumber,
        
        [Parameter(Mandatory = $True)]
        [int] $TotalNumber,
        
        [Parameter(Mandatory = $false)]
        [string] $Description = "Attendere...",

        [Parameter(Mandatory = $false)]
        [int] $MaxTextLength = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("PS5", "PS7", "Inline")]
        [string] $Style = "Inline"
    )

    $scriptName = Split-Path $PSCommandPath -Leaf
    $now = Get-Date

    # Inizializzazione storico per Moving Average (Stima ETA più precisa)
    if ($null -eq $Script:ProgressHistory) {
        $Script:ProgressHistory = [System.Collections.Generic.Queue[PSCustomObject]]::new()
    }

    $Script:ProgressHistory.Enqueue([PSCustomObject]@{ Time = $now; Item = $PassNumber })
    while ($Script:ProgressHistory.Count -gt 10) {
        [void]$Script:ProgressHistory.Dequeue()
    }

    $timeSpan = $now - $Script:StartTime

    # Calcolo velocità
    $firstSample = $Script:ProgressHistory.Peek()
    $deltaSeconds = ($now - $firstSample.Time).TotalSeconds
    $deltaItems = $PassNumber - $firstSample.Item

    if ($deltaSeconds -gt 0 -and $deltaItems -gt 0) {
        $itemsPerSecond = $deltaItems / $deltaSeconds
    } else {
        $itemsPerSecond = $PassNumber / ($timeSpan.TotalSeconds + 0.001)
    }

    # Formattazione Velocità a larghezza fissa (es: "  5.0/sec" o " 120.5/min")
    if (([Math]::Round(($itemsPerSecond), 0)) -lt 60) {
        $speedVal = [Math]::Round(($itemsPerSecond * 60), 1)
        $Speed = "{0,5:0.0}/min" -f $speedVal
    } else {
        $speedVal = [Math]::Round(($itemsPerSecond), 1)
        $Speed = "{0,5:0.0}/sec" -f $speedVal
    }

    # Protezione su PassNumber
    $cappedPass = [Math]::Min($PassNumber, $TotalNumber)
    $pctRatio = $cappedPass / $TotalNumber
    $pctVal = [Math]::Round(($pctRatio * 100), 0)
    
    # 1. Percentuale a 4 caratteri (es: "  5%", " 50%", "100%")
    $percentualeStr = "{0,4}" -f "$pctVal%"
    
    # 2. Conteggio Item a larghezza fissa (es: " 05/100" o "005/100")
    $totalDigits = $TotalNumber.ToString().Length
    $passStr = $cappedPass.ToString().PadLeft($totalDigits, ' ')
    $itemCountStr = "$passStr/$TotalNumber"

    # 3. Tempo Trascorso (HH:mm:ss)
    $elapsedStr = "{0:D2}:{1:D2}:{2:D2}" -f [int]$timeSpan.Hours, [int]$timeSpan.Minutes, [int]$timeSpan.Seconds
    
    # Base della stringa di stato
    $StatusString = "$percentualeStr $itemCountStr $elapsedStr"
    
	# 4. ETA e Velocità a larghezza fissa (solo dal 4° elemento in poi)
    if ($cappedPass -gt 3) {
        $remainingSeconds = 0
        if ($TotalNumber -gt 3 -and $cappedPass -lt $TotalNumber) {
            if ($itemsPerSecond -gt 0) {
                $remainingSeconds = ($TotalNumber - $cappedPass) / $itemsPerSecond
            }
            $eta = $now.AddSeconds($remainingSeconds)
            
            if ($now.ToString("d") -eq $eta.ToString("d")) {
                $FormattedETA = $eta.ToString("HH:mm:ss")
            } else {
                $FormattedETA = $eta.ToString("dd/MM/yyyy HH:mm:ss")
            }
            $StatusString += " ETA=$FormattedETA $Speed"
        } 
        elseif ($cappedPass -eq $TotalNumber) {
            $StatusString += " ETA=--:--:-- $Speed"
        }
    } else {
        # Per i primi 3 elementi stampa uno spazio vuoto equivalente
        # Formato standard ETA (8 o 19 caratteri) + " ETA=" (5) + " " (1) + Speed (10)
        # Se la data è del giorno stesso, ETA è HH:mm:ss (8 char).
        # Calcolo padding fisso coerente con l'output standard del giorno (24 spazi complessivi):
        $StatusString += "                       "
    }
	
    # 5. Normalizzazione Descrizione in base a $MaxTextLength
    if ($MaxTextLength -gt 0) {
        if ($Description.Length -gt $MaxTextLength) {
            $FormattedDescription = $Description.Substring(0, $MaxTextLength)
        } else {
            $FormattedDescription = $Description.PadRight($MaxTextLength, ' ')
        }
    } else {
        $FormattedDescription = $Description
    }

    switch ($Style) {
        "PS7" {
            if ($PSVersionTable.PSVersion.Major -ge 7 -and $null -ne $PSStyle) {
                $PSStyle.Progress.View = 'Minimal'
            }
            $wpParams = @{
                Activity        = $FormattedDescription
                Status          = $StatusString
                PercentComplete = $pctVal
            }
            if ($TotalNumber -gt 3) { $wpParams['SecondsRemaining'] = $remainingSeconds }
            Write-Progress @wpParams
        }

        "Inline" {
            Write-Progress -Activity $FormattedDescription -Completed

            $prefix = "$FormattedDescription [$StatusString] "
            $suffix = ""
            
            $cleanPrefix = $prefix -replace '\x1b\[[0-9;]*m', ''
            
            $bufferWidth = $Host.UI.RawUI.WindowSize.Width
            $availableWidth = $bufferWidth - $cleanPrefix.Length - $suffix.Length - 1

            if ($availableWidth -gt 5) {
                $filledLength = [Math]::Round($availableWidth * $pctRatio)
                $emptyLength = $availableWidth - $filledLength
                
                $filledBar = [string]::new([char]0x2588, $filledLength)
                $emptyBar = [string]::new([char]0x2591, $emptyLength)
                $bar = $filledBar + $emptyBar
            } else {
                $bar = ""
            }

            $outLine = "`r$prefix$bar$suffix"
            $padLen = $bufferWidth - ($cleanPrefix.Length + $bar.Length + $suffix.Length)
            if ($padLen -gt 0) { $outLine += [string]::new([char]32, $padLen) }

            Write-Host -NoNewline $outLine
        }

        Default { # PS5
            if ($PSVersionTable.PSVersion.Major -ge 7 -and $null -ne $PSStyle) {
                $PSStyle.Progress.View = 'Classic'
            }
            $wpParams = @{
                Activity        = $FormattedDescription
                Status          = $StatusString
                PercentComplete = $pctVal
            }
            if ($TotalNumber -gt 3) { $wpParams['SecondsRemaining'] = $remainingSeconds }
            Write-Progress @wpParams
        }
    }
    
    $Host.UI.RawUI.WindowTitle = "$pctVal% ${scriptName}"
}

function Write-LogAdvanced {
    <#
      .SYNOPSIS
          Scrive un testo in "formato log" nella console e/o in un LogFile.
    #>

    Param(
        [Parameter(Mandatory = $True)]
        [String] $Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARN", "ERROR", "FATAL", "DEBUG")]
        [String] $Level = "INFO",

        [Parameter(Mandatory = $false)]
        [String] $LogFile = "$(Split-Path $PSCommandPath -Parent)\Log\$(Split-Path $PSCommandPath -Leaf).log",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Console", "Log", "Progressbar", "ConsoleLog", "ConsoleProgressbar", "LogProgressbar", "ConsoleLogProgressbar")]
        [String] $Mode = "Console",

        [Parameter(Mandatory = $false)]
        [Int] $CurrentItem,

        [Parameter(Mandatory = $false)]
        [Int] $TotalItems,

        [Parameter(Mandatory = $false)]
        [Int] $MaxTextLength = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("PS5", "PS7", "Inline")]
        [String] $ProgressStyle = "Inline"
    )

    $TimeStamp = (Get-Date).ToString("HH:mm:ss,fff")
    $Line = "$TimeStamp $Level $Message"

    # CONSOLE:
    if ($Mode.Contains("Console")) {
        if ($Level -in "ERROR", "FATAL") { 
            Write-Host "$TimeStamp $Level" -BackgroundColor "Red" -ForegroundColor "White" -NoNewline
            if ($Mode.Contains("Progressbar")) { Write-Host " [${CurrentItem}/${TotalItems}]" -NoNewLine }
            Write-Host " $Message"
        }
        elseif ($Level -eq "WARN") { 
            Write-Host "$TimeStamp $Level " -BackgroundColor "Yellow" -ForegroundColor "Black" -NoNewline
            if ($Mode.Contains("Progressbar")) { Write-Host " [${CurrentItem}/${TotalItems}]" -NoNewLine }
            Write-Host " $Message"
        }
        elseif ($Level -eq "DEBUG") { 
            Write-Host "$TimeStamp $Level" -BackgroundColor "Cyan" -ForegroundColor "Black" -NoNewline
            if ($Mode.Contains("Progressbar")) { Write-Host " [${CurrentItem}/${TotalItems}]" -NoNewLine }
            Write-Host " $Message"
        }
        elseif ($Level -eq "INFO") {
            Write-Host "$TimeStamp $Level " -BackgroundColor "Gray" -ForegroundColor "Black" -NoNewline
            if ($Mode.Contains("Progressbar")) { Write-Host " [${CurrentItem}/${TotalItems}]" -NoNewLine }
            Write-Host " $Message"
        }
    }

    # LOG:
    if ($Mode.Contains("Log")) {
        $logFolder = $(Split-Path $LogFile -Parent)
        if (!(Test-Path $logFolder)) { New-Item -ItemType Directory -Path "$logFolder" -Force | Out-Null }
        try {
            Add-Content $LogFile -Value $Line
        }
        catch {
            Write-Host "Impossibile scrivere nel file di log ""$LogFile""!" -BackgroundColor "Red" -ForegroundColor "White"
        }
    }

    # PROGRESSBAR:
    if ($Mode.Contains("Progressbar")) {
        $CurrentItem = [int]$CurrentItem
        $TotalItems = [int]$TotalItems
        AggiornaProgressbar -PassNumber $CurrentItem -TotalNumber $TotalItems -Description $Message -MaxTextLength $MaxTextLength -Style $ProgressStyle
    }
}

function Install-ScoopApp {
    param (
        [string]$Package
    )
    Write-Verbose -Message "[Scoop] Verifica installazione $Package"
    if (! (scoop info $Package 2>$null).Installed ) {
        Write-Verbose -Message "scoop: Installazione $Package..."
        scoop install $Package
    } else {
        Write-Verbose -Message "scoop: Aggiornamento $Package..."
        scoop update $Package
    }
}

function Enable-ScoopBucket {
    param (
        [string]$Bucket
    )
    if (!($(scoop bucket list 2>$null).Name -eq "$Bucket")) {
        Write-Verbose -Message "scoop: Aggiunta bucket $Bucket..."
        scoop bucket add $Bucket
    } else {
        Write-Verbose -Message "scoop: Bucket $Bucket gia' presente."
    }
}
#EndRegion



$ScriptName = Split-Path $PSCommandPath -Leaf
$Host.UI.RawUI.WindowTitle = "${ScriptName}"

#Region PacchettiFondamentali
$ArrayPacchettiFondamentali = @(
    [PSCustomObject]@{ Nome = 'Winget'; Comando = { Install-ScoopApp "winget" } },
    [PSCustomObject]@{ Nome = 'PowerShell'; Comando = { Install-ScoopApp "pwsh" } },
    [PSCustomObject]@{ Nome = 'Terminal-Icons'; Comando = { Install-ScoopApp "terminal-icons" } },
    [PSCustomObject]@{ Nome = 'Oh My Posh'; Comando = { Install-ScoopApp "oh-my-posh" } },
    [PSCustomObject]@{ Nome = 'Fastfetch'; Comando = { Install-ScoopApp "fastfetch" } },
    [PSCustomObject]@{ Nome = 'bat'; Comando = { Install-ScoopApp "bat" } },
    [PSCustomObject]@{ Nome = 'CompletionPredictor'; Comando = { Install-Module -Name CompletionPredictor -Repository PSGallery -Force -Scope CurrentUser } },
    [PSCustomObject]@{ Nome = 'Clink'; Comando = { Install-ScoopApp "clink" } },
    [PSCustomObject]@{ Nome = 'Clink-completions'; Comando = { Install-ScoopApp "clink-completions" } },
    [PSCustomObject]@{ Nome = 'Clink autorun'; Comando = { clink autorun install } },
    [PSCustomObject]@{ Nome = 'fzf'; Comando = { Install-ScoopApp "fzf" } },
    [PSCustomObject]@{ Nome = 'PSFzf'; Comando = { Install-Module PSFzf -Force -Scope CurrentUser } },
    [PSCustomObject]@{ Nome = 'gsudo'; Comando = { Install-ScoopApp "gsudo" } },
    [PSCustomObject]@{ Nome = 'Less'; Comando = { Install-ScoopApp "less" } },
    [PSCustomObject]@{ Nome = 'eza'; Comando = { Install-ScoopApp "eza" } },
    [PSCustomObject]@{ Nome = 'ov'; Comando = { Install-ScoopApp "ov" } },
    [PSCustomObject]@{ Nome = 'CascadiaCode Nerd Font'; Comando = { Install-ScoopApp "CascadiaCode-NF" } },
    [PSCustomObject]@{ Nome = 'scoop-completion'; Comando = { Install-ScoopApp "scoop-completion" } },
    [PSCustomObject]@{ Nome = 'zoxide'; Comando = { Install-ScoopApp "zoxide" } }
)
#EndRegion

#Region PacchettiFacoltativi
$ArrayPacchettiFacoltativi = @(
    [PSCustomObject]@{ Nome = 'btop'; Comando = { Install-ScoopApp "btop" } },
    [PSCustomObject]@{ Nome = 'byenow'; Comando = { Install-ScoopApp "byenow" } },
    [PSCustomObject]@{ Nome = 'csview'; Comando = { Install-ScoopApp "csview" } },
    [PSCustomObject]@{ Nome = 'chafa'; Comando = { Install-ScoopApp "chafa" } },
    [PSCustomObject]@{ Nome = 'Dust'; Comando = { Install-ScoopApp "dust" } },
    [PSCustomObject]@{ Nome = 'genact'; Comando = { Install-ScoopApp "genact" } },
    [PSCustomObject]@{ Nome = 'fd'; Comando = { Install-ScoopApp "fd" } },
    [PSCustomObject]@{ Nome = 'Figurine'; Comando = { Install-ScoopApp "figurine" } },
    [PSCustomObject]@{ Nome = 'Figlet'; Comando = { Install-ScoopApp "figlet" } },
    [PSCustomObject]@{ Nome = 'file'; Comando = { Install-ScoopApp "file" } },
    [PSCustomObject]@{ Nome = 'gping'; Comando = { Install-ScoopApp "gping" } },
    [PSCustomObject]@{ Nome = 'grex'; Comando = { Install-ScoopApp "grex" } },
    [PSCustomObject]@{ Nome = 'lf'; Comando = { Install-ScoopApp "lf" } },
    [PSCustomObject]@{ Nome = 'Micro'; Comando = { Install-ScoopApp "micro" } },
    [PSCustomObject]@{ Nome = 'UbuntuMono Nerd Font'; Comando = { Install-ScoopApp "ubuntumono-nf" } },
    [PSCustomObject]@{ Nome = 'peco'; Comando = { Install-ScoopApp "peco" } },
    [PSCustomObject]@{ Nome = 'PowerPing'; Comando = { Install-ScoopApp "powerping" } },
    [PSCustomObject]@{ Nome = 'procs'; Comando = { Install-ScoopApp "procs" } },
    [PSCustomObject]@{ Nome = 'q'; Comando = { Install-ScoopApp "q" } },
    [PSCustomObject]@{ Nome = 's'; Comando = { Install-ScoopApp "s" } },
    [PSCustomObject]@{ Nome = 'say'; Comando = { Install-ScoopApp "say" } },
    [PSCustomObject]@{ Nome = 'serve'; Comando = { Install-ScoopApp "serve" } },
    [PSCustomObject]@{ Nome = 'SpeedTest'; Comando = { Install-ScoopApp "speedtest-cli" } },
    [PSCustomObject]@{ Nome = 'tldr++'; Comando = { Install-ScoopApp "tldr" } },
    [PSCustomObject]@{ Nome = 'tre'; Comando = { Install-ScoopApp "tre-command" } },
    [PSCustomObject]@{ Nome = 'Trippy'; Comando = { Install-ScoopApp "trippy" } },
    [PSCustomObject]@{ Nome = 'xsv'; Comando = { Install-ScoopApp "xsv" } },
    [PSCustomObject]@{ Nome = 'y-cruncher'; Comando = { Install-ScoopApp "y-cruncher" } }
)
#EndRegion

# Scelta tra installazione base o completa:
Write-Host @"
          _    __  __       ___ _    ___
 _ _ _  _| |__|  \/  |_  _ / __| |  |_ _|
| '_| || | '_ \ |\/| | || | (__| |__ | |
|_|  \_,_|_.__/_|  |_|\_, |\___|____|___| v0.07
                      |__/

"@ -ForegroundColor "Yellow"

$listaBase = $ArrayPacchettiFondamentali.Nome -join ', '
$listaFacoltativa = $ArrayPacchettiFacoltativi.Nome -join ', '

Write-Host "Installazione BASE ($($ArrayPacchettiFondamentali.Count) pacchetti):" -ForegroundColor Cyan
Write-Host "$listaBase`n" -ForegroundColor Gray

Write-Host "Installazione COMPLETA (BASE + $($ArrayPacchettiFacoltativi.Count) pacchetti facoltativi):" -ForegroundColor Cyan
Write-Host "$listaFacoltativa`n" -ForegroundColor Gray

# Funzione menu interattivo: Navigazione Frecce / Tasto di scelta rapida
function Invoke-InteractiveMenu {
    param(
        [string]$Message,
        [array]$Options
    )

    $selectedIndex = 0
    $keyInfo = $null
    [Console]::CursorVisible = $false

    # Salva la posizione corrente del cursore per aggiornare l'interfaccia sullo stesso punto
    $topPos = [Console]::CursorTop

    while ($true) {
        [Console]::SetCursorPosition(0, $topPos)
        Write-Host "$Message`n" -ForegroundColor Yellow

        for ($i = 0; $i -lt $Options.Count; $i++) {
            $opt = $Options[$i]
            if ($i -eq $selectedIndex) {
                Write-Host "  > [$($opt.HotKey)] $($opt.Label) " -ForegroundColor Cyan -NoNewline
                Write-Host "- $($opt.Description)" -ForegroundColor DarkGray
            } else {
                Write-Host "    [$($opt.HotKey)] $($opt.Label) " -ForegroundColor Gray -NoNewline
                Write-Host "- $($opt.Description)" -ForegroundColor DarkGray
            }
        }

        Write-Host "`nUsa [Freccia Su/Giu] o premi la lettera scorciatoia." -ForegroundColor DarkGray

        $keyInfo = [Console]::ReadKey($true)

        # Gestione Frecce e Invio
        if ($keyInfo.Key -eq [ConsoleKey]::UpArrow) {
            $selectedIndex = if ($selectedIndex -gt 0) { $selectedIndex - 1 } else { $Options.Count - 1 }
        }
        elseif ($keyInfo.Key -eq [ConsoleKey]::DownArrow) {
            $selectedIndex = if ($selectedIndex -lt $Options.Count - 1) { $selectedIndex + 1 } else { 0 }
        }
        elseif ($keyInfo.Key -eq [ConsoleKey]::Enter) {
            [Console]::CursorVisible = $true
            Write-Host ""
            return $selectedIndex
        }

        # Selezione immediata via Lettera (senza premere Invio)
        $charPressed = $keyInfo.KeyChar.ToString().ToUpper()
        for ($i = 0; $i -lt $Options.Count; $i++) {
            if ($Options[$i].HotKey.ToUpper() -eq $charPressed) {
                [Console]::CursorVisible = $true
                Write-Host ""
                return $i
            }
        }
    }
}

# Definizione opzioni del menu
$menuOptions = @(
    @{ HotKey = 'B'; Label = 'Base';     Description = "Installazione dei soli $($ArrayPacchettiFondamentali.Count) pacchetti fondamentali" },
    @{ HotKey = 'C'; Label = 'Completa'; Description = "Installazione di tutti i $($ArrayPacchettiFondamentali.Count + $ArrayPacchettiFacoltativi.Count) pacchetti (Base + Facoltativi)" }
)

# Esecuzione del menu
$scelta = Invoke-InteractiveMenu -Message "Scegli la suite di pacchetti da installare:" -Options $menuOptions

if ($scelta -eq 0) {
    $tipoInstallazione = "BASE"
    $ArrayAppDaInstallare = $ArrayPacchettiFondamentali
} else {
    $tipoInstallazione = "COMPLETA"
    $ArrayAppDaInstallare = $ArrayPacchettiFondamentali + $ArrayPacchettiFacoltativi
}

Write-LogAdvanced "Avvio installazione $($tipoInstallazione) ($($ArrayAppDaInstallare.Count) pacchetti)." -Level "INFO" -Mode "Console"

# Scoop: Installazione/aggiornamento (INFO: https://scoop.sh):
Write-LogAdvanced "scoop: Installazione/aggiornamento..." -Level "INFO" -Mode "Console"
try {
    scoop update | Out-Null
}
catch {
    Set-ExecutionPolicy RemoteSigned -Scope Process -Force
    Invoke-Expression "& {$(Invoke-RestMethod get.scoop.sh)} -RunAsAdmin"
}

# Scoop: installazione git (serve per aggiornamento di scoop e per aggiungere buckets):
Install-ScoopApp("git")

# Scoop: disabilita warnings per i download:
Write-LogAdvanced "scoop: Configurazione..." -Level "INFO" -Mode "Console"
scoop config aria2-warning-enabled false

# Scoop: aggiunta buckets:
Enable-ScoopBucket("extras")
Enable-ScoopBucket("nerd-fonts")

# Installa Windows Terminal se necessario:
if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) { 
    Install-ScoopApp("windows-terminal")
}

# Calcolo preventivo di $maxTextLength su tutti gli elementi da elaborare
$maxTextLength = 0
foreach ($app in $ArrayAppDaInstallare) {
    $len = "Installazione $($app.Nome)".Length
    if ($len -gt $maxTextLength) {
        $maxTextLength = $len
    }
}

# Installazione dei pacchetti:
$Script:StartTime = Get-Date    # Ri-definisco così da avere un'indicazione più realistica
$c = 0    # Contatore pacchetto in fase di installazione
foreach ($app in $ArrayAppDaInstallare) {
    $c++
    $msg = "Installazione $($app.Nome)"
    Write-LogAdvanced -Message $msg -Level "INFO" -Mode "Progressbar" -CurrentItem $c -TotalItems ($ArrayAppDaInstallare.Count) -MaxTextLength $maxTextLength -ProgressStyle "Inline"
    & $app.Comando
}

# Clear eventuale riga rimanente della progressbar inline
Write-Host ""

#Region Restore Configuration Files
Write-LogAdvanced "Avvio ripristino dotfiles e configurazioni CLI..." -Level "INFO" -Mode "Console"

$scriptDir = Split-Path $PSCommandPath -Parent
$restoreScript = Join-Path $scriptDir "rubMyCLI-dotfiles-restore.ps1"

if (Test-Path $restoreScript) {
    & $restoreScript
} else {
    Write-Host "ATTENZIONE: Lo script di ripristino '$restoreScript' non e' stato trovato!" -ForegroundColor Red
}
#EndRegion



# Chiusura script:
$Host.UI.RawUI.WindowTitle = "100% [${ScriptName}]"
$elapsedTotal = (Get-Date) - $Script:StartTime
$elapsedTotalStr = "{0:D2}:{1:D2}:{2:D2}" -f [int]$elapsedTotal.Hours, [int]$elapsedTotal.Minutes, [int]$elapsedTotal.Seconds

Write-LogAdvanced "Script $ScriptName concluso in $elapsedTotalStr." -Level "INFO" -Mode "Console"
Write-Host "Premi [Invio] per terminare... " -BackgroundColor "blue" -ForegroundColor "white" -NoNewline
Read-Host -AsSecureString | Out-Null