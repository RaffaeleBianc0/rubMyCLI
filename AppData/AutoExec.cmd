@REM ========================================================================
@REM Richiamare questo script da Windows Terminal - Opzioni - Profilo CMD - Riga di comando:
@REM %SystemRoot%\System32\cmd.exe /K "%APPDATA%\AutoExec.cmd"
@REM ========================================================================

@echo OFF

"%USERPROFILE%\scoop\apps\clink\current\clink_x64.exe" inject



: FastFetch/Winfetch/Cmdfetch
for /f "delims=" %%a in ('where.exe FastFetch.exe') do @set MYFULLPATH=%%a
if not "[%MYFULLPATH%]"=="[]" (
	cls
	echo.
	"%MYFULLPATH%" --file-raw "%APPDATA%\WindowsTerminal\LogoMSDOS.chafa"
	goto :Ambiente
) 

for /f "delims=" %%a in ('where.exe winfetch.ps1') do @set MYFULLPATH=%%a
if not "[%MYFULLPATH%]"=="[]" (
	cls
	powershell -NoLogo -NoProfile -File "%MYFULLPATH%" -image "%APPDATA%\WindowsTerminal\LogoMSDOS.png" -imgwidth 40
	goto :Ambiente
) 

for /f "delims=" %%a in ('where.exe cmdfetch.exe') do @set MYFULLPATH=%%a
if not "[%MYFULLPATH%]"=="[]" (
	cls
	"%MYFULLPATH%"
	goto :Ambiente
)



:Ambiente
set DIRCMD=/O:GN
set PROMPT=$e[44m $T$H$H$H $e[7m$e[1;97m $P $e[0m$_$e[94m$G$e[0m$S
set LESS=-iMq --incsearch --line-num-width=5 --use-color
@REM set FZF_DEFAULT_OPTS=--height 50% --layout reverse --info inline
@REM set FZF_CTRL_T_OPTS=--preview 'bat --color=always --style=numbers --line-range :256 {}'
@REM set FZF_ALT_C_OPTS=--preview 'tre --color always --limit 3 {}'

doskey   d=ndir.exe -1aj $*
doskey   l=eza.exe --bytes --classify --color-scale --git        --group-directories-first --header --hyperlink --icons           --long                           --time-style long-iso        $*
doskey  ll=eza.exe --bytes --classify --color-scale --git --grid --group-directories-first --header --hyperlink --icons           --long                           --time-style long-iso        $*
doskey lll=eza.exe                                  --git        --group-directories-first          --hyperlink --icons                                                                         $*
doskey   t=eza.exe         --classify                                                               --hyperlink         --level 2 --long --no-filesize --only-dirs --time-style long-iso --tree $*
@REM doskey l=lsd.exe --long --ignore-glob DumpStack.log --ignore-glob DumpStack.log.tmp --ignore-glob hiberfil.sys --ignore-glob pagefile.sys --ignore-glob PerfLogs --ignore-glob Recovery --ignore-glob swapfile.sys --ignore-glob "System Volume Information" $*
@REM doskey t=lsd.exe --tree --directory-only $*
