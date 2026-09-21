<img alt="wt" src="https://github.com/user-attachments/assets/0c437393-4e3b-424a-ae44-7eeefaf8fc76" />

`rubMyCLI.ps1` customizes both **PowerShell** and **CMD** by installing a curated set of CLI tools through [Scoop](https://scoop.sh).  
 
---
 
## ✨ Features
 
- 📦 **Two install profiles**: Base (essentials) and Full (Base + optional tools)
- 🔁 **Idempotent**: already-installed packages are updated instead of reinstalled, so it is safe to re-run at any time
- 🗂️ **Automatic prerequisites**: installs/updates Scoop, Git, the `extras` and `nerd-fonts` buckets, and Windows Terminal if missing
- ♻️ **Dotfiles restore hook**: optionally runs a companion script to restore your configuration files
- 📊 **Live progress bar** and **Colored, timestamped console log** (`INFO` / `WARN` / `ERROR` / `DEBUG`)



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
 


# TODO
Gather all the dotfiles in a single folder as **hard links** to the original files - like:

```batch
mklink  /H  %USERPROFILE%\dotfiles\appname.cfg  %USERPROFILE%\.config\original_path\original.cfg
```

... and modify the corresponding PS1 dotfile backup & restore scripts to manage the same structure.
