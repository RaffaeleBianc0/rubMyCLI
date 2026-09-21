<#
=============================================================================
.SYNOPSIS
    Personalizza la CLI (interfaccia a linea di comando) di Windows,
    sia PowerShell sia CMD.
=============================================================================
#>

# Previene prompt interattivi e blocchi di esecuzione
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Host "Confermare l'installazione di NuGet se richiesta di seguito (prerequisito necessario):" -ForegroundColor Cyan
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force
}
Clear-Host
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction SilentlyContinue

#Region Funzioni
function AggiornaProgressbar {
    <#
    .SYNOPSIS
        Aggiornamento Progressbar a larghezza piena con testo in negativo.
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

    if ($null -eq $Script:ProgressHistory) {
        $Script:ProgressHistory = [System.Collections.Generic.Queue[PSCustomObject]]::new()
    }

    $Script:ProgressHistory.Enqueue([PSCustomObject]@{ Time = $now; Item = $PassNumber })
    while ($Script:ProgressHistory.Count -gt 10) {
        [void]$Script:ProgressHistory.Dequeue()
    }

    $timeSpan = $now - $Script:StartTime

    $firstSample = $Script:ProgressHistory.Peek()
    $deltaSeconds = ($now - $firstSample.Time).TotalSeconds
    $deltaItems = $PassNumber - $firstSample.Item

    if ($deltaSeconds -gt 0 -and $deltaItems -gt 0) {
        $itemsPerSecond = $deltaItems / $deltaSeconds
    } else {
        $itemsPerSecond = $PassNumber / ($timeSpan.TotalSeconds + 0.001)
    }

    $cappedPass = [Math]::Min($PassNumber, $TotalNumber)
    $pctRatio = $cappedPass / $TotalNumber
    $pctVal = [Math]::Round(($pctRatio * 100), 0)
    
    # 1. Sinistra: % avanzamento, nn/mm, descrizione
    $percentualeStr = "{0,3}%" -f $pctVal
    $totalDigits = $TotalNumber.ToString().Length
    $passStr = $cappedPass.ToString().PadLeft($totalDigits, ' ')
    $itemCountStr = "$passStr/$TotalNumber"

    $leftText = " $percentualeStr | $itemCountStr | $Description"

    # 2. Destra: elapsed time, ETA
    $elapsedStr = "{0:D2}:{1:D2}:{2:D2}" -f [int]$timeSpan.Hours, [int]$timeSpan.Minutes, [int]$timeSpan.Seconds
    
    if ($cappedPass -gt 3 -and $TotalNumber -gt 3 -and $cappedPass -lt $TotalNumber) {
        $remainingSeconds = if ($itemsPerSecond -gt 0) { ($TotalNumber - $cappedPass) / $itemsPerSecond } else { 0 }
        $eta = $now.AddSeconds($remainingSeconds)
        $FormattedETA = if ($now.ToString("d") -eq $eta.ToString("d")) { $eta.ToString("HH:mm:ss") } else { $eta.ToString("dd/MM/yyyy HH:mm:ss") }
        $rightText = "$elapsedStr | ETA=$FormattedETA "
    } elseif ($cappedPass -eq $TotalNumber) {
        $rightText = "$elapsedStr | ETA=--:--:-- "
    } else {
        $rightText = "$elapsedStr | ETA=--:--:-- "
    }

    switch ($Style) {
        "Inline" {
            Write-Progress -Activity $Description -Completed

            $bufferWidth = $Host.UI.RawUI.WindowSize.Width

            # Spazio di riempimento tra il blocco di sinistra e quello di destra
            $spacerLen = $bufferWidth - ($leftText.Length + $rightText.Length)
            if ($spacerLen -lt 1) {
                $spacer = " "
            } else {
                $spacer = [string]::new([char]32, $spacerLen)
            }

            $fullLineText = "$leftText$spacer$rightText"
            if ($fullLineText.Length -gt $bufferWidth) {
                $fullLineText = $fullLineText.Substring(0, $bufferWidth)
            }

            # Sequenze ANSI: \e[7m (Inverti colori/negativo), \e[0m (Reset)
            # Only the filled part of the line (proportional to the percentage) is colored:
            # \e[46m = cyan background, \e[30m = black text
            $esc = [char]27
            $filledLen = [int][Math]::Round($fullLineText.Length * $pctRatio)
            $filledLen = [Math]::Max(0, [Math]::Min($filledLen, $fullLineText.Length))
            $filledPart = $fullLineText.Substring(0, $filledLen)
            $emptyPart = $fullLineText.Substring($filledLen)
            $negativeLine = "${esc}[46;30m$filledPart${esc}[0m$emptyPart"

            # Riga vuota prima della progressbar
            Write-Host ""
            Write-Host "`r$negativeLine"
        }

        Default { # PS5 / PS7 standard
            $wpParams = @{
                Activity        = $Description
                Status          = "$percentualeStr $itemCountStr $elapsedStr $rightText"
                PercentComplete = $pctVal
            }
            Write-Progress @wpParams
        }
    }
    
    $Host.UI.RawUI.WindowTitle = "$pctVal% ${scriptName}"
}

function Write-LogAdvanced {
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
        Write-Verbose -Message "Scoop: Installazione $Package..."
        scoop install $Package
    } else {
        Write-Verbose -Message "Scoop: Aggiornamento $Package..."
        scoop update $Package
    }
}

function Enable-ScoopBucket {
    param (
        [string]$Bucket
    )
    if (!($(scoop bucket list 2>$null).Name -eq "$Bucket")) {
        Write-Verbose -Message "Scoop: Aggiunta bucket $Bucket..."
        scoop bucket add $Bucket
    } else {
        Write-Verbose -Message "Scoop: Bucket $Bucket gia' presente."
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
    [PSCustomObject]@{ Nome = 'bat'; Comando = { Install-ScoopApp "bat" } },
    [PSCustomObject]@{ Nome = 'CompletionPredictor'; Comando = { Install-Module -Name CompletionPredictor -Repository PSGallery -Force -Scope CurrentUser } },
    [PSCustomObject]@{ Nome = 'Clink'; Comando = { Install-ScoopApp "clink" } },
    [PSCustomObject]@{ Nome = 'Clink-completions'; Comando = { Install-ScoopApp "clink-completions" } },
    [PSCustomObject]@{ Nome = 'Clink autorun'; Comando = { clink autorun install } },
    [PSCustomObject]@{ Nome = 'fzf'; Comando = { Install-ScoopApp "fzf" } },
    [PSCustomObject]@{ Nome = 'PSFzf'; Comando = { Install-Module PSFzf -Force -Scope CurrentUser } },
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
    [PSCustomObject]@{ Nome = 'Fastfetch'; Comando = { Install-ScoopApp "fastfetch" } },
    [PSCustomObject]@{ Nome = 'fd'; Comando = { Install-ScoopApp "fd" } },
    [PSCustomObject]@{ Nome = 'Figurine'; Comando = { Install-ScoopApp "figurine" } },
    [PSCustomObject]@{ Nome = 'Figlet'; Comando = { Install-ScoopApp "figlet" } },
    [PSCustomObject]@{ Nome = 'file'; Comando = { Install-ScoopApp "file" } },
    [PSCustomObject]@{ Nome = 'gping'; Comando = { Install-ScoopApp "gping" } },
    [PSCustomObject]@{ Nome = 'grex'; Comando = { Install-ScoopApp "grex" } },
    [PSCustomObject]@{ Nome = 'lf'; Comando = { Install-ScoopApp "lf" } },
    [PSCustomObject]@{ Nome = 'Micro'; Comando = { Install-ScoopApp "micro" } },
    [PSCustomObject]@{ Nome = 'UbuntuMono Nerd Font'; Comando = { Install-ScoopApp "ubuntumono-nf" } },
    [PSCustomObject]@{ Nome = 'Oh My Posh'; Comando = { Install-ScoopApp "oh-my-posh" } },
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
|_|  \_,_|_.__/_|  |_|\_, |\___|____|___| v0.11
                      |__/

"@ -ForegroundColor "Yellow"

$listaBase =$ArrayPacchettiFondamentali.Nome -join ', '
$listaFacoltativa = $ArrayPacchettiFacoltativi.Nome -join ', '

Write-Host "Installazione BASE ($($ArrayPacchettiFondamentali.Count) app):" -ForegroundColor Cyan
Write-Host "$listaBase`n" -ForegroundColor Gray

Write-Host "Installazione COMPLETA (BASE + $($ArrayPacchettiFacoltativi.Count) app facoltative):" -ForegroundColor Cyan
Write-Host "$listaFacoltativa`n" -ForegroundColor Gray

# Funzione menu interattivo: Navigazione Frecce / Tasto di scelta rapida
function Invoke-InteractiveMenu {
    param(
        [string]$Message,
        [array]$Options
    )

    $selectedIndex = 0
    $confirmed = $false
    # Block height: message + blank + options + blank + hint
    $blockHeight = $Options.Count + 4

    [Console]::CursorVisible = $false
    $topPos = [Console]::CursorTop

    try {
        while ($true) {
            [Console]::SetCursorPosition(0, $topPos)
            Write-Host "$Message`n" -ForegroundColor Yellow

            for ($i = 0; $i -lt $Options.Count; $i++) {
                $opt = $Options[$i]
                if ($confirmed -and $i -eq $selectedIndex) {
                    # Final state: chosen line rewritten in White, in place
                    Write-Host "  > [$($opt.HotKey)] $($opt.Label) - $($opt.Description)" -ForegroundColor White
                } elseif (-not $confirmed -and $i -eq $selectedIndex) {
                    Write-Host "  > [$($opt.HotKey)] $($opt.Label) " -ForegroundColor Cyan -NoNewline
                    Write-Host "- $($opt.Description)" -ForegroundColor DarkGray
                } else {
                    Write-Host "    [$($opt.HotKey)] $($opt.Label) " -ForegroundColor Gray -NoNewline
                    Write-Host "- $($opt.Description)" -ForegroundColor DarkGray
                }
            }

            Write-Host "`nUsa [Freccia Su/Giu] o premi la lettera scorciatoia." -ForegroundColor DarkGray

            # Recompute the top row from the cursor: stays correct even if the buffer scrolled
            $topPos = [Math]::Max(0, [Console]::CursorTop - $blockHeight)

            if ($confirmed) { return $selectedIndex }

            $keyInfo = [Console]::ReadKey($true)

            if ($keyInfo.Key -eq [ConsoleKey]::UpArrow) {
                $selectedIndex = if ($selectedIndex -gt 0) { $selectedIndex - 1 } else { $Options.Count - 1 }
            }
            elseif ($keyInfo.Key -eq [ConsoleKey]::DownArrow) {
                $selectedIndex = if ($selectedIndex -lt $Options.Count - 1) { $selectedIndex + 1 } else { 0 }
            }
            elseif ($keyInfo.Key -eq [ConsoleKey]::Enter) {
                $confirmed = $true
            }
            else {
                $charPressed = $keyInfo.KeyChar.ToString().ToUpper()
                for ($i = 0; $i -lt $Options.Count; $i++) {
                    if ($Options[$i].HotKey.ToUpper() -eq $charPressed) {
                        $selectedIndex = $i
                        $confirmed = $true
                        break
                    }
                }
            }
        }
    }
    finally {
        [Console]::CursorVisible = $true
    }
}

# Definizione opzioni del menu
$menuOptions = @(
    @{ HotKey = 'B'; Label = 'Base';     Description = "Installazione delle $($ArrayPacchettiFondamentali.Count) app fondamentali" },
    @{ HotKey = 'C'; Label = 'Completa'; Description = "Installazione di tutte le $($ArrayPacchettiFondamentali.Count + $ArrayPacchettiFacoltativi.Count) app (Base + Facoltative)" }
)

# Esecuzione del menu
$scelta = Invoke-InteractiveMenu -Message "Scegli la suite da installare:" -Options $menuOptions

if ($scelta -eq 0) {
    $tipoInstallazione = "BASE"
    $ArrayAppDaInstallare = $ArrayPacchettiFondamentali
} else {
    $tipoInstallazione = "COMPLETA"
    $ArrayAppDaInstallare = $ArrayPacchettiFondamentali + $ArrayPacchettiFacoltativi
}

Write-Host ""

Write-LogAdvanced "Avvio installazione $($tipoInstallazione) ($($ArrayAppDaInstallare.Count) app)." -Level "INFO" -Mode "Console"

# Scoop: Installazione/aggiornamento
Write-LogAdvanced "Scoop: Installazione/aggiornamento..." -Level "INFO" -Mode "Console"
try {
    scoop update | Out-Null
}
catch {
    Invoke-Expression "& {$(Invoke-RestMethod get.scoop.sh)}"
}

# Scoop: installazione git
Install-ScoopApp("git")

# Scoop: disabilita warnings per i download
Write-LogAdvanced "Scoop: Configurazione..." -Level "INFO" -Mode "Console"
scoop config aria2-warning-enabled false

# Scoop: aggiunta buckets
Enable-ScoopBucket("extras")
Enable-ScoopBucket("nerd-fonts")

# Installa Windows Terminal se necessario
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

# Installazione dei pacchetti
$Script:StartTime = Get-Date 
$c = 0
foreach ($app in $ArrayAppDaInstallare) {
    $c++
    $msg = "Installazione $($app.Nome)"
    Write-LogAdvanced -Message $msg -Level "INFO" -Mode "Progressbar" -CurrentItem $c -TotalItems ($ArrayAppDaInstallare.Count) -MaxTextLength $maxTextLength -ProgressStyle "Inline"
    & $app.Comando
}

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

# Chiusura script
$Host.UI.RawUI.WindowTitle = "100% [${ScriptName}]"
$elapsedTotal = (Get-Date) - $Script:StartTime
$elapsedTotalStr = "{0:D2}:{1:D2}:{2:D2}" -f [int]$elapsedTotal.Hours, [int]$elapsedTotal.Minutes, [int]$elapsedTotal.Seconds

Write-LogAdvanced "Script $ScriptName concluso in $elapsedTotalStr." -Level "INFO" -Mode "Console"
Write-Host "Premi [Invio] per terminare... " -BackgroundColor "blue" -ForegroundColor "white" -NoNewline
Read-Host -AsSecureString | Out-Null