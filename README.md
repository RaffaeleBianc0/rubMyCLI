<img alt="wt" src="https://github.com/user-attachments/assets/0c437393-4e3b-424a-ae44-7eeefaf8fc76" />

`rubMyCLI.ps1` customizes both **PowerShell** and **CMD** by installing a curated set of CLI tools through [Scoop](https://scoop.sh).  
 
---

## 📽️ Video footage
- [Installation]()
- [Usage]()

_Files are ready... soon to be published_



## ✨ Features
 
- 📦 **Two install profiles**: Base (essentials) and Full (Base + optional tools)
- 🔁 **Idempotent**: already-installed packages are updated instead of reinstalled, so it is safe to re-run at any time
- 🗂️ **Automatic prerequisites**: installs/updates Scoop, Git, the `extras` and `nerd-fonts` buckets, and Windows Terminal if missing
- ♻️ **Dotfiles restore hook**: optionally runs a companion script to restore your configuration files
- 📊 **Live progress bar** and **Colored, timestamped console log** (`INFO` / `WARN` / `ERROR` / `DEBUG`)
- 💻 **Rich PowerShell $PROFILE** is installed (see below for the detailed information)



## 🎯 Benefits
- Set up a new machine (or repair an old one) in a single run
- Consistent CLI environment across all your Windows PCs
- No admin rights needed for the tools themselves: everything is installed per-user via Scoop
- Sensible defaults: fuzzy finding, smart `cd`, syntax highlighting, icons, better pagers and Nerd Fonts out of the box



## 📋 Requirements
 
| Requirement | Notes |
|---|---|
| Windows 10 / 11 | Windows PowerShell 5.1 or PowerShell 7+ |
| Internet connection | Needed for Scoop, PSGallery and package downloads |
| Regular (non-elevated) user session | Recommended: the Scoop installer does not support elevated shells by default |



## 🚀 Installation & Usage
 
1. **Clone** the repository (or download the script):
```powershell
   git clone https://github.com/RaffaeleBianc0/rubMyCLI.git
   cd rubMyCLI
```
 
2. **Run** the script:
```powershell
   .\rubMyCLI.ps1
```
 
   The script sets the execution policy to `Bypass` for the **current process only**, so no permanent system change is made.
 
3. **Confirm NuGet** if prompted (one-time prerequisite for installing PowerShell modules).
4. **Choose a profile** from the menu:
   | Key | Profile | Description |
   |---|---|---|
   | `B` | Base | the essential items |
   | `C` | Full | Base + a lot of cool optional tools |
   Use `↑` / `↓` and `Enter`, or press the hotkey directly.
5. **Wait** for the progress bar to complete, then press `Enter` to close.
> 💡 Open a new terminal window at the end so that PATH changes, fonts and modules are picked up.
 
## 📦 What gets installed
 
### Base profile
 
| Tool | Purpose |
|---|---|
| Winget | Windows package manager |
| PowerShell (`pwsh`) | Modern cross-platform PowerShell |
| Terminal-Icons | File and folder icons in PowerShell listings |
| bat | `cat` with syntax highlighting |
| CompletionPredictor | Predictive IntelliSense-style completions |
| Clink + clink-completions | Bash-like line editing and completions for CMD |
| Clink autorun | Enables Clink automatically in every CMD session |
| fzf + PSFzf | Fuzzy finder and its PowerShell integration |
| Less | Classic pager |
| eza | Modern `ls` replacement |
| ov | Feature-rich terminal pager |
| CascadiaCode Nerd Font | Font with icon glyphs |
| scoop-completion | Tab completion for Scoop |
| zoxide | Smarter `cd` that learns your habits |
 
### Optional tools (Full profile)
 
`btop` · `byenow` · `csview` · `chafa` · `dust` · `genact` · `fastfetch` · `fd` · `figurine` · `figlet` · `file` · `gping` · `grex` · `lf` · `micro` · `UbuntuMono Nerd Font` · `oh-my-posh` · `peco` · `PowerPing` · `procs` · `q` · `s` · `say` · `serve` · `speedtest-cli` · `tldr` · `tre-command` · `trippy` · `xsv` · `y-cruncher`


 
## ⚙️ How it works
 
1. Trusts the PowerShell Gallery and installs the NuGet provider if missing
2. Installs or updates Scoop, then installs `git`
3. Adds the `extras` and `nerd-fonts` buckets
4. Installs Windows Terminal if `wt.exe` is not found (for Win10 PCs)
5. Installs every package of the selected profile (or updates it if already present)
6. Runs `rubMyCLI-dotfiles-restore.ps1` from the same folder, if it exists



## 🔧 Customization
 
Packages are defined as simple lists at the top of the script. To add or remove a tool, edit one of these arrays:
 
```powershell
$ArrayPacchettiFondamentali   # Base profile
$ArrayPacchettiFacoltativi    # Optional tools (Full profile)
```
 
Each entry follows the same pattern:
 
```powershell
[PSCustomObject]@{ Nome = 'bat'; Comando = { Install-ScoopApp "bat" } }
```
 
## 🗃️ Dotfiles restore (optional)
 
If a file named `rubMyCLI-dotfiles-restore.ps1` is present **in the same folder** as the main script, it is executed at the end of the installation. If it is missing, the script prints a warning and continues.


 
## 🛠️ Troubleshooting
 
- **Icons look broken / show squares** → set your terminal font to a Nerd Font (e.g. `CascadiaCode Nerd Font`)
- **Scoop refuses to install** → run the script from a non-elevated PowerShell window
- **A package fails to install** → re-run the script; already-installed items are simply updated
- **Progress bar looks garbled** → use Windows Terminal or a console with ANSI escape sequence support



## ⚠️ Notes
 
- The script installs software from third-party sources (Scoop buckets, PSGallery). Review the package lists before running it on a production machine.
- Console messages are currently in Italian.
 


# 💻 Powershell $PROFILE details
A Windows Terminal oriented PowerShell profile that works on both **Windows PowerShell 5.1** and **PowerShell 7+**.  
It configures command-line editing, fuzzy finding, a custom prompt, modern replacements for common commands, and a set of one-letter shortcuts for system info, networking, weather and market tickers.

### Highlights
- Loads **only inside Windows Terminal** (detected via `$env:WT_SESSION`); in any other host it just prints the PowerShell version and exits.
- Graceful degradation: every optional feature is version-gated (PS 5.1 vs 7+) or tool-gated, so the profile keeps working when a tool is missing.
- Built-in **load-time profiler** to debug startup slowdowns.

### Requirements

| Tool / module | Used for | Required |
|---|---|---|
| Windows Terminal (`wt.exe`) | Profile activation, split-pane layouts | Yes |
| `PSReadLine` | Edit mode, key bindings, predictions | Yes (ships with PowerShell) |
| `PSFzf` + `fzf` | Fuzzy history, file and tab completion | Yes (module is imported unconditionally) |
| `zoxide` | Smart `cd` | Yes (initialized unconditionally) |
| `scoop` + `scoop-completion` | Scoop tab completion | Yes (imported unconditionally) |
| `Terminal-Icons` | File icons in listings | PowerShell 7+ |
| `CompletionPredictor` | Completion-based predictions | PowerShell 7.2+ |
| `oh-my-posh` | Prompt theme | Optional |
| `eza` | `l`, `ll`, `lll`, `t` | Optional |
| `fastfetch` / `winfetch` | `f` | Optional (built-in fallback) |
| `broot`, `gping`, `powerping`, `btop`, `speedtest`, `ticker`, `tickrs` | Shortcut commands | Optional, per command |
| `bat`, `tre` | Previews inside fzf | Optional |
| `powershell-yaml` | `tt` | Auto-installed on first use |

Most tools can be installed with [Scoop](https://scoop.sh) - and actually _have been_, if you used rubMyCLI.

### Debug timing (optional)
Set `$debugMessages = $true` at the top of the file to print how long each module/function block took to load, plus the total profile load time.

### Editing experience

| Feature | Behavior |
|---|---|
| Edit mode | PSReadLine `Windows` mode |
| `Tab` | Menu completion (PS 5.1) or fzf-powered completion (PS 7+) |
| Predictions (PS 7+) | Inline view, sourced from history and plugins (`CompletionPredictor` on 7.2+) |
| `Ctrl+T` | Fuzzy file picker with a `bat` syntax-highlighted preview |
| `Ctrl+R` | Fuzzy reverse history search |
| Icons (PS 7+) | `Terminal-Icons` for directory listings |
| `z` / `zi` | `zoxide` smart directory jumping |
| `scoop <Tab>` | Scoop command completion |

### Prompt

The built-in prompt shows, in order:

1. **Clock** (`H:mm:ss`) on a blue background.
2. **Full current path** on a white background.
3. **Last command duration and outcome**: a red `!` badge is shown when the last command failed.
4. A `>` on a new line, **red when running as Administrator**, white otherwise.

On PowerShell 7+, if `oh-my-posh` is installed and `%APPDATA%\oh-my-posh\rb.omp.json` exists, the oh-my-posh theme replaces the built-in prompt.

### Command shortcuts

| Command | Description |
|---|---|
| `f` | System info banner. Uses `fastfetch` with a custom logo, falls back to `winfetch` (PS 7+), and finally to a native PowerShell implementation with a Windows 11 logo, colored usage bars (RAM, disk, battery) and a color palette strip. |
| `l` | Long listing via `eza`: git status, icons, exact byte sizes, ISO timestamps, directories first. |
| `ll` | Same as `l`, in grid layout. |
| `lll` | Compact `eza` listing with git status and icons. |
| `t` | Two-level directory tree (directories only). |
| `d` | `Get-ChildItem` piped to `Format-Table -AutoSize`. |
| `c` | Clears the screen by scrolling, leaving the prompt on the last line (keeps scrollback). |
| `br` | `broot` file navigator that changes the current directory on exit. |
| `p [host...]` | `gping` graph against `8.8.8.8` plus any hosts you pass. Defaults to `8.8.8.8` and `one.one.one.one`. |
| `pp [host]` | Continuous `powerping` with timestamps. Defaults to `8.8.8.8`. |
| `i` | Internet dashboard: opens a Windows Terminal layout with `btop`, `speedtest`, `gping` and `powerping`. |
| `tt` | Portfolio dashboard: reads tickers from `~\.ticker.yaml` and opens `ticker` and `tickrs` in side-by-side panes. |
| `demo` | Multi-pane showcase layout with `gping`, `btop` and `tickrs`. |
| `w [location]` | Weather from [wttr.in](https://wttr.in). With no argument, shows the current IP-based location plus a predefined list of cities. |
| `ww` | Detailed weather forecast view for a fixed location. |

#### `tt` details

`tt` parses `~\.ticker.yaml`, collects every `symbol` under `groups[].holdings[]`, removes duplicates and passes them to `tickrs`. If the `powershell-yaml` module is missing, it is installed for the current user on first run. Compatible with the [ticker](https://github.com/achannarasappa/ticker) config format.

### Environment variables

The profile writes the following **persistent user-level** variables to `HKCU:\Environment` on every startup. They apply to new processes, not to the current session.

| Variable | Purpose |
|---|---|
| `FZF_DEFAULT_OPTS` | fzf layout and color theme |
| `FZF_CTRL_T_OPTS` | `bat` preview for `Ctrl+T` |
| `FZF_ALT_C_OPTS` | `tre` preview for the fzf directory picker (only effective if the PSFzf `Alt+C` binding is enabled) |
| `LESS` | `less` options: case-insensitive search, incremental search, line numbers, colors |
| `EXA_GRID_ROWS` | Row count for `eza` grid output |

### Customization

Items you will probably want to edit:

- **Weather cities** in `w` and the fixed location in `ww`.
- **Ticker symbols** used by `demo`.
- **Logo files** in `%APPDATA%\WindowsTerminal\` (`LogoPS.chafa`, `LogoPS5.chafa`, `LogoPS.png`) and the disks listed in the `winfetch` call.
- **oh-my-posh theme** path (`%APPDATA%\oh-my-posh\rb.omp.json`).
- **Ping targets** in `p`, `pp` and `i`.

### Installation (only if you did NOT use rubMyCLI automatic restore script)

Copy the file to the location reported by `$PROFILE` (for PowerShell 7 typically `Documents\PowerShell\Microsoft.PowerShell_profile.ps1`, for Windows PowerShell 5.1 `Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`), then open a new Windows Terminal tab.



# 📌 TODO
1. Change all the internal texts to English (currently Italian) - only if somebody asks for this.
2. Gather all the dotfiles in a single folder as **hard links** to the original files - like:
```batch
mklink  /H  %USERPROFILE%\dotfiles\appname.cfg  %USERPROFILE%\.config\original_path\original.cfg
```
... and modify the corresponding PS1 dotfile backup & restore scripts to manage the same structure.
