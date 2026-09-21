$debugMessages = $false	# Impostare a $true per visualizzare i tempi di caricamento dei singoli Moduli / Funzioni

$scriptStartTime = Get-Date

# Carico questo $PROFILE solo in Windows Terminal:
if (-not $env:WT_SESSION) { Write-Host "Powershell $($PSVersionTable.PSVersion)" -ForegroundColor yellow; return }

$indiceComponente = 0
$componentiCaricati = ""

# Abilito il grassetto con "$esc[1m" (INFO: https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#text-formatting):
$esc = [char]27

function NewItem {
	param(
        [Parameter(Mandatory = $true)]
        [string] $itemName
    )

	$script:nomeComponente = $itemName
	$script:itemStart = Get-Date 
	if ($PSVersionTable.PSVersion.Major -gt 5) { 
		$p=[Math]::Floor((++$script:indiceComponente+0)/($script:indiceComponente+1) * 100)
		Write-Progress -Activity "Caricamento Moduli/Funzioni..." -Status "$p% $nomeComponente..." -PercentComplete $p
	}
}

function PrintDebug {
	if ($debugMessages) { 
		$componentiCaricati = ("$componentiCaricati $nomeComponente")
		$itemTimespan = (Get-Date) - $script:itemStart
		$timeSpanFromStart = (Get-Date) - $scriptStartTime
		"+{0:n2}s = {1:n2}s`t $nomeComponente" -f $itemTimespan.TotalSeconds, $timespanFromStart.TotalSeconds 
	}
}




# FastFetch / Winfetch:
function f() {
	if (Get-Command fastfetch.exe -errorAction SilentlyContinue) {
		if ($PSVersionTable.PSVersion.Major -gt 5) { 
			fastfetch.exe --logo $env:APPDATA\WindowsTerminal\LogoPS.chafa
		}
		else { 
			fastfetch.exe --logo $env:APPDATA\WindowsTerminal\LogoPS5.chafa
		}
		Write-Host ""
	}

	elseif ((Get-Command winfetch.ps1 -errorAction SilentlyContinue) -And ($PSVersionTable.PSVersion.Major -gt 5)) {
		# Winfetch come piano B solo su pwsh>5, ma è più lento
		Clear-Host
		winfetch.ps1 "$env:APPDATA\WindowsTerminal\LogoPS.png" -ascii -imgwidth 40 -cpustyle "bartext" -memorystyle "bartext" -diskstyle "bartext" -batterystyle "bartext" -showdisks @("C:", "G:") -showpkgs ""
	}

	else { 	
		# Nel caso non ci siano installati né FastFetch né Winfetch
		# System info with Windows 11 logo - native PowerShell 5 only
		$ErrorActionPreference = 'SilentlyContinue'

		$block = [string][char]0x2588   # full block
		$light = [string][char]0x2591   # light shade

		function Get-Bar([double]$percent, [int]$length = 16) {
			$filled = [int][math]::Round($percent / 100 * $length)
			$filled = [math]::Max(0, [math]::Min($length, $filled))
			return ($block * $filled) + ($light * ($length - $filled))
		}

		function Get-LoadColor([double]$percent) {
			if ($percent -lt 60) { return 'Green' }
			if ($percent -lt 85) { return 'Yellow' }
			return 'Red'
		}

		# Fill = bar fill percentage, Load = value used to pick the bar color
		function New-Line([string]$Type, [string]$Key = '', [string]$Value = '', [double]$Fill = -1, [double]$Load = -1) {
			[pscustomobject]@{ Type = $Type; Key = $Key; Value = $Value; Fill = $Fill; Load = $Load }
		}

		# --- Collect data ---
		$os      = Get-CimInstance Win32_OperatingSystem
		$cs      = Get-CimInstance Win32_ComputerSystem
		$cpu     = Get-CimInstance Win32_Processor | Select-Object -First 1
		$gpus    = @(Get-CimInstance Win32_VideoController | Where-Object { $_.Name })
		$sysDrv  = if ($env:SystemDrive) { $env:SystemDrive } else { 'C:' }
		$disk    = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$sysDrv'"
		$battery = Get-CimInstance Win32_Battery | Select-Object -First 1

		$osName  = $os.Caption -replace 'Microsoft ', ''
		$uptime  = (Get-Date) - $os.LastBootUpTime
		$cpuName = ($cpu.Name -replace '\s+', ' ').Trim()

		# Memory values are in KB, dividing by 1MB gives GB
		$ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
		$ramUsed  = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
		$ramPct   = if ($ramTotal -gt 0) { [math]::Round($ramUsed / $ramTotal * 100) } else { 0 }

		$diskTotal = [math]::Round($disk.Size / 1GB, 1)
		$diskUsed  = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 1)
		$diskPct   = if ($disk.Size -gt 0) { [math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100) } else { 0 }

		$resGpu = $gpus | Where-Object { $_.CurrentHorizontalResolution } | Select-Object -First 1

		# --- Build lines ---
		$title = "$env:USERNAME@$env:COMPUTERNAME"
		$lines = @()
		$lines += New-Line 'title' -Value $title
		$lines += New-Line 'sep'   -Value ('-' * $title.Length)
		$lines += New-Line 'info' 'Host'   $cs.Model
		$lines += New-Line 'info' 'OS'     "$osName ($($os.OSArchitecture)) build $($os.BuildNumber)"
		$lines += New-Line 'info' 'Uptime' "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
		$lines += New-Line 'info' 'Shell'  "PowerShell $($PSVersionTable.PSVersion)"
		$lines += New-Line 'info' 'CPU'    "$cpuName ($($cpu.NumberOfCores)C/$($cpu.NumberOfLogicalProcessors)T)"
		foreach ($g in $gpus) {
			$lines += New-Line 'info' 'GPU' $g.Name
		}
		if ($resGpu) {
			$lines += New-Line 'info' 'Screen' "$($resGpu.CurrentHorizontalResolution)x$($resGpu.CurrentVerticalResolution) @ $($resGpu.CurrentRefreshRate)Hz"
		}
		$lines += New-Line 'info' 'RAM' "${ramUsed}GB / ${ramTotal}GB ($ramPct%)" $ramPct $ramPct
		$lines += New-Line 'info' "Disk $sysDrv" "${diskUsed}GB / ${diskTotal}GB ($diskPct%)" $diskPct $diskPct
		if ($battery) {
			$batPct = [double]$battery.EstimatedChargeRemaining
			# Bar shows charge level, color is inverted so that low charge is red
			$lines += New-Line 'info' 'Battery' "$batPct%" $batPct (100 - $batPct)
		}

		# --- Logo: Windows 11, 4 squares with a gap (height 11, width 22) ---
		$logoH   = 11
		$logoW   = 22
		$gapRow  = 5
		$gapCols = 2
		$sqW     = ($logoW - $gapCols) / 2

		$total  = [math]::Max($lines.Count, $logoH)
		$offset = [math]::Max(0, [math]::Floor(($lines.Count - $logoH) / 2))

		Write-Host ''
		for ($i = 0; $i -lt $total; $i++) {
			# Logo column
			$j = $i - $offset
			if ($j -ge 0 -and $j -lt $logoH -and $j -ne $gapRow) {
				$logoPart = ($block * $sqW) + (' ' * $gapCols) + ($block * $sqW)
			} else {
				$logoPart = ' ' * $logoW
			}
			Write-Host $logoPart -NoNewline -ForegroundColor Blue
			Write-Host '   ' -NoNewline

			# Info column
			if ($i -ge $lines.Count) { Write-Host ''; continue }
			$l = $lines[$i]
			switch ($l.Type) {
				'title' { Write-Host $l.Value -ForegroundColor Cyan }
				'sep'   { Write-Host $l.Value -ForegroundColor DarkGray }
				default {
					Write-Host ('{0,-8}' -f $l.Key) -NoNewline -ForegroundColor White
					if ($l.Fill -ge 0) {
						# Bar first (same column for all bars), then the numeric value
						Write-Host (Get-Bar $l.Fill) -NoNewline -ForegroundColor (Get-LoadColor $l.Load)
						Write-Host (' ' + $l.Value) -ForegroundColor Yellow
					} else {
						Write-Host $l.Value -ForegroundColor Yellow
					}
				}
			}
		}

		# Empty line, then color palette strip
		Write-Host ''
		Write-Host (' ' * ($logoW + 3)) -NoNewline
		foreach ($c in 'DarkRed','DarkGreen','DarkYellow','DarkBlue','DarkMagenta','DarkCyan','Gray','White') {
			Write-Host ($block * 2) -NoNewline -ForegroundColor $c
		}
		Write-Host "`n"
		# Write-Host "PowerShell $($PSVersionTable.PSVersion.ToString())" -ForegroundColor yellow
		Write-Host ""
	}
}

if ($debugMessages) { Write-Host "$esc[1m+This  = Total`t Funzioni e moduli caricati:" -ForegroundColor blue }




NewItem("PSReadLine")
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineKeyHandler -Chord Tab -Function MenuComplete 	# TAB instead of CTRL+SPACE
if ($PSVersionTable.PSVersion.Major -gt 5) { 
	Set-PSReadLineOption -PredictionViewStyle InlineView
	Set-PSReadLineOption -PredictionSource HistoryAndPlugin
}
PrintDebug




NewItem("PSFzf")
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
if ($PSVersionTable.PSVersion.Major -gt 5) { 	# FZF su Tab non funziona su Windows PowerShell
	Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {Invoke-FzfTabCompletion} 
}
Set-ItemProperty -Path HKCU:\Environment -Name 'FZF_DEFAULT_OPTS' -Value "--height=50% --layout=reverse --info=inline --color=bg+:#222222,bg:#444444,border:#777777,spinner:#98BC99,hl:#719872,fg:#D9D9D9,header:#719872,info:#BDBB72,pointer:#E12672,marker:#E17899,fg+:#D9D9D9,preview-bg:#222222,prompt:#98BEDE,hl+:#98BC99"
Set-ItemProperty -Path HKCU:\Environment -Name 'FZF_CTRL_T_OPTS' -Value "--keep-right --preview 'bat --color=always --style=numbers --line-range :256 {}'"
Set-ItemProperty -Path HKCU:\Environment -Name 'FZF_ALT_C_OPTS' -Value "--keep-right --preview 'tre --color always --limit 3 {}'"
PrintDebug





NewItem("Terminal-Icons")
if ($PSVersionTable.PSVersion.Major -gt 5) {
	Import-Module Terminal-Icons
}
PrintDebug





NewItem("Prompt")
function Test-IsAdministrator {  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}
$global:timeSpanOld = $null
function Prompt {
	# Risultato "errorlevel" dell'ultimo comando:
	$lastExecutionStatus = $?

	# Titolo della finestra:
	if (Test-IsAdministrator) { $adminString = "{ADMIN} " } else { $adminString = "" }
	if ($pwd.Path.Split("\")[-1] -eq "") {
		$MyShortPwd = $($pwd.Drive.Root)
	} else {
		$MyShortPwd = "$($pwd.Path.Split('\')[-1])"
	} 
	[console]::Title = "$($adminString)$MyShortPwd [PS" + $PSVersionTable.PSVersion.Major + "]"

	
	# Ora corrente:
	Write-Host " $(Get-Date -format "H:mm:ss") " -NoNewline -BackgroundColor blue -ForegroundColor gray 

	# Cartella corrente:
	$MyPwd = "$($pwd.path)"
	# if (($pwd.Path.Split('\').count -gt 4)) { $MyPwd = "$($pwd.path.split('\')[0], '...', $pwd.path.split('\')[-3], $pwd.path.split('\')[-2], $pwd.path.split('\')[-1] -join ('\'))" } 	# Accorcia il path se troppo lungo, introducendo "..." prima degli ultimi N livelli di cartelle
	Write-Host " $($MyPwd) " -BackgroundColor white -ForegroundColor blue -NoNewline

	# Tempo di esecuzione dell'ultimo comando:
	$history = Get-History -ErrorAction Ignore -Count 1
	if ($history) {
		$ts = New-TimeSpan $history.StartExecutionTime $history.EndExecutionTime
		if ($global:timeSpanOld -ne $ts) {
			$global:timeSpanOld = $ts
			if ($lastExecutionStatus -eq $true) {
				# Write-Host ' OK ' -ForegroundColor white -BackgroundColor green -NoNewline
			} else {
				Write-Host ' ! ' -ForegroundColor white -BackgroundColor red -NoNewline				
			}
			switch ($ts) {
				{ $_.TotalSeconds -lt 10 } { 
					[int]$d = $_.TotalMilliseconds
					' {0}ms ' -f ($d) | Write-Host -ForegroundColor black -BackgroundColor darkgreen -NoNewline
					break
				}
				{ $_.TotalMinutes -lt 1 } { 
					[int]$d = $_.TotalSeconds
					' {0}s ' -f ($d) | Write-Host -ForegroundColor black -BackgroundColor darkgreen -NoNewline
					break
				}
				{ $_.TotalMinutes -ge 1 } { 
					" {0:HH}h {0:mm}m {0:ss}s " -f ([datetime]$ts.Ticks) | Write-Host -ForegroundColor black -BackgroundColor darkgreen -NoNewline
					break
				}
			}
		}
	}

	# Prompt:
	Write-Host ""
	if (Test-IsAdministrator) { 
		Write-Host '>' -NoNewline -ForegroundColor red
	} else {
		Write-Host '>' -NoNewline -ForegroundColor white
	}
	return " "
}
if ($PSVersionTable.PSVersion.Major -gt 5 -and
    (Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and
    (Test-Path "$env:APPDATA\oh-my-posh\rb.omp.json")) {
	& ([ScriptBlock]::Create((oh-my-posh init pwsh --config "$env:APPDATA\oh-my-posh\rb.omp.json" --print) -join "`n"))
}
PrintDebug





NewItem("Less")
Set-ItemProperty -Path HKCU:\Environment -Name 'LESS' -Value "-iMq --incsearch --line-num-width=5 --use-color"
PrintDebug





NewItem("zoxide")
Invoke-Expression (& { (zoxide init powershell | Out-String) })
PrintDebug





NewItem("scoop-completion")
Import-Module "$($(Get-Item $(Get-Command scoop.ps1).Path).Directory.Parent.FullName)\modules\scoop-completion"
PrintDebug




NewItem("CompletionPrediction")
if ( (($PSVersionTable.PSVersion.Major -eq 7) -And ($PSVersionTable.PSVersion.Minor -ge 2)) -Or ($PSVersionTable.PSVersion.Major -gt 7) ) {
	Import-Module -Name CompletionPredictor
	Set-PSReadLineOption -PredictionSource HistoryAndPlugin
}
PrintDebug




NewItem("Function + Alias")

# br -> Broot:
function br() {
	$tmp = [System.IO.Path]::GetTempFileName()
	broot.exe --outcmd "$tmp" $args
	$cd = Get-Content "$tmp"
	Remove-Item -Force "$tmp"
	if ($null -ne $cd) {
		$dir = $cd.Substring(3)	
		if (Test-Path -PathType Container "$dir") {
			if ("$dir" -ne "$pwd") {
				Push-Location "$dir"
			}
		}
	}
}

# c -> cls con prompt nell'ultima riga
function c() { 1..$($Host.UI.RawUI.BufferSize.Height) | ForEach-Object {""} }

# d -> gci autosize:
function d() { Get-ChildItem $args | Format-Table -AutoSize }

# demo!
function demo() {
	wt.exe -M gping --watch-interval 0.5 --buffer 60 --vertical-margin 2 --horizontal-margin 2 --color blue www.google.com `; split-pane -s 0.50 btop `; split-pane --horizontal -s 0.50 tickrs -x --summary --update-interval 30 --symbols VWCE.MI,XDEW.MI,EXUS.MI,EIMI.MI,WGLD.MI,EGOV.MI,XEON.MI --hide-help --hide-toggle `; move-focus left `; split-pane --horizontal -s 0.50
}

# i (powerping + gping + speedtest)
function i() {
	# wt.exe -M gping --watch-interval 0.5 --buffer 60 --vertical-margin 2 --horizontal-margin 2 --color blue 8.8.8.8 `; split-pane --horizontal -s 0.50 btop --preset 3 `; split-pane -s 0.50 powerping --timestamp --infinite 8.8.8.8 `; move-focus left `; split-pane --horizontal -s 0.50 pwsh -NoProfile -NoExit -Command "speedtest.exe --selection-details" `; move-focus down
	wt.exe -M btop --preset 3 `; split-pane --horizontal -s 0.50 pwsh -NoProfile -NoExit -Command "speedtest.exe --selection-details" `; move-focus up `; split-pane -s 0.70 gping --watch-interval 0.5 --buffer 60 --vertical-margin 2 --horizontal-margin 2 --color blue 8.8.8.8 `; move-focus down `; split-pane -s 0.45 powerping --timestamp --infinite 8.8.8.8 `; move-focus left
}

# l ll lll t -> eza:
Set-ItemProperty -Path HKCU:\Environment -Name 'EXA_GRID_ROWS' -Value '4'
function l()   { eza.exe --bytes --classify --color-scale --git        --group-directories-first --header --hyperlink --icons           --long                           --time-style long-iso        $args }
function ll()  { eza.exe --bytes --classify --color-scale --git --grid --group-directories-first --header --hyperlink --icons           --long                           --time-style long-iso        $args }
function lll() { eza.exe                                  --git        --group-directories-first          --hyperlink --icons                                                                         $args }
function t()   { eza.exe         --classify                                                               --hyperlink         --level 2 --long --no-filesize --only-dirs --time-style long-iso --tree $args }
	# function l() { lsd.exe --long --ignore-glob DumpStack.log --ignore-glob DumpStack.log.tmp --ignore-glob hiberfil.sys --ignore-glob pagefile.sys --ignore-glob PerfLogs --ignore-glob Recovery --ignore-glob swapfile.sys --ignore-glob "System Volume Information" $args }
	# function t() { lsd.exe --tree --directory-only $args }

# p -> gping:
function p() { 
	if ($args) { 
		$extraArg = '8.8.8.8'
		# TODO: if ($args contiene $extraArg) { $there = $args } else { $there = "$extraArg $args" }
		$there = $extraArg + " " + $args
		Write-Host ""
		# Write-Host "Eseguo gPing in finestra dedicata..." -NoNewLine
		# cmd.exe /C start "gPing running..." 
		gping --watch-interval 0.5 --buffer 60 --vertical-margin 2 --horizontal-margin 2 --color darkgray $there.Split(" ")
	} 
	else { 
		$there = '8.8.8.8 one.one.one.one' 
		Write-Host ""
		# Write-Host "Eseguo gPing in finestra dedicata..." -NoNewLine
		# cmd.exe /C start "gPing running..." 
		gping --watch-interval 0.5 --buffer 60 --vertical-margin 2 --horizontal-margin 2 --color darkgray $there.Split(" ")
	}
}

# pp -> powerping:
function pp() { 
	if ($args) { 
		$there = $args
	} 
	else { 
		$there = '8.8.8.8'
	}
	Write-Host ""
	powerping --timestamp --infinite $there
}

# tt -> ticker + tickrs
function tt() {
	# Specifica il percorso al tuo file YAML
	$tickerYamlFullPath = "$($env:userprofile)\.ticker.yaml"
	if (-not (Test-Path -Path $tickerYamlFullPath)) {
		Write-Error "File YAML di configurazione per ticker non trovato: '$tickerYamlFullPath'"
		exit 1
	}

	# Installazione e importazione del modulo powershell-yaml:
	try {
		if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
			Write-Host "Modulo powershell-yaml non trovato. Installazione in corso..." -ForegroundColor cyan
			Install-Module -Name powershell-yaml -Scope CurrentUser -Force -Confirm:$false
		}
		Import-Module powershell-yaml
	}
	catch {
		Write-Error "Modulo powershell-yaml non installato. Risolvere manualmente."
		exit 1
	}

	# Parsing del file YAML:
	try {
		$Config = Get-Content -Path $tickerYamlFullPath | ConvertFrom-YAML
	}
	catch {
		Write-Error "Errore nella lettura o nel parsing del file YAML: $($_.Exception.Message)"
		exit 1
	}

	# Estrazione dei symbols:
	$Tickers = @()
	foreach ($Group in $Config.groups) {
		# Verifica se l'oggetto ha la proprietà 'holdings' e se non è nulla
		if ($Group.holdings -is [System.Collections.IEnumerable] -and $Group.holdings) {
			# Itera su ciascuna "holding" all'interno del gruppo
			foreach ($Holding in $Group.holdings) {
				# Estrae il valore del campo 'symbol'
				$Tickers += $Holding.symbol
			}
		}
	}

	# Formattazione dei tickers:
	$ElencoSimboliUnivoci = ($Tickers | Select-Object -Unique) -join ","

	# Esecuzione di ticker e tickrs in due pannelli affiancati:
	wt.exe ticker `; split-pane -s 0.34 tickrs -x --summary --update-interval 300 --symbols $ElencoSimboliUnivoci --hide-help --hide-toggle `; move-focus left

}

# Weather/Meteo:
function w() {
	Write-Host "Meteo attuale ($(Get-Date -format "d MMMM yyyy, H:mm")):" -ForegroundColor yellow
	
	if     ($PSVersionTable.PSVersion.Major -eq 5) { $format = 4 }
	elseif ($PSVersionTable.PSVersion.Major -gt 5) { $format = '%l:+%c+🌡️%t+🌬️%w+🏖️%u+☔%p+🌅%S+🌇%s\n' } # $format = '%l:+%c+🌡️%t+🌬️%w+🏖️%u+☔%p+🌅%S+🌇%s\n'

	if ($args) { 
		$location = $args[0]
		Write-Progress -Activity "Recupero informazioni meteo da wttr.in..." -Status $location -PercentComplete 66
		(Invoke-WebRequest "http://wttr.in/$($location)?format=$($format)" -UserAgent 'curl').Content.Trim()
	}
	else { 
		$here = (Invoke-WebRequest "http://wttr.in?format=%l" -UserAgent 'curl').Content.Trim()
		$locations = @($here, "Piove di Sacco", "Treviso", "Oderzo", "Lorenzago")
		$maxLength = ($locations | Measure-Object -Maximum Length).Maximum
		
		$widx = 0
		foreach ($location in $locations) {
			Write-Progress -Activity "Recupero informazioni meteo da wttr.in..." -Status $location -PercentComplete $([Math]::Floor(++$widx/($widx+1) * 100))
			if ($location -eq $here) { 
				$result = (Invoke-WebRequest "http://wttr.in?format=%c+🌡️%t+🌬️%w+🏖️%u+☔%p+🌅%S+🌇%s" -UserAgent 'curl').Content.Trim()
				# Write-Host "$result " -NoNewLine
				Write-Host ("{0,-$maxLength} {1}" -f $location, $result) -NoNewLine
				Write-Host " (Posizione in base all'IP)" -ForegroundColor "cyan"		
			}
			else { 
				$result = (Invoke-WebRequest "http://wttr.in/$($location)?format=2" -UserAgent 'curl').Content.Trim()
				Write-Host ("{0,-$maxLength} {1}" -f $location, $result)
			}
		}
	}

	
}

function ww() {
	(Invoke-WebRequest "http://v2d.wttr.in/Piove%20di%20Sacco" -UserAgent 'curl').Content.Trim()
}

PrintDebug





# NewItem("gsudo")
# if (scoop info gsudo 2>$null) { Import-Module 'gsudoModule' }
# PrintDebug





# Visualizzo la durata del caricamento del profilo:
$elapsed = (Get-Date) - $scriptStartTime
if ($debugMessages) { 
	Write-Host "         $([Math]::Round($elapsed.TotalSeconds, 2))s" -ForegroundColor 'blue' -NoNewline
	Write-Host "`t $esc[1mTempo totale caricamento `$PROFILE"  -ForegroundColor 'blue'
} 
else {
# 	Write-Host "$esc[1m`$PROFILE loading time" -ForegroundColor 'DarkYellow' -NoNewline
# 	Write-Host ": $([Math]::Round($elapsed.TotalSeconds, 2))s"
	1..$($Host.UI.RawUI.BufferSize.Height) | ForEach-Object {""}
}

#  ___ ___  ___
# | __/ _ \| __|
# | _| (_) | _|
# |___\___/|_|
#
