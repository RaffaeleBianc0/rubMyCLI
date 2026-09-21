# ===== WINFETCH CONFIGURATION =====

# $image = "~/winfetch.png"
# $noimage = $true

# Display image using ASCII characters
# $ascii = $true

# Set the version of Windows to derive the logo from.
# $logo = "Windows 10"

# Specify width for image/logo
# $imgwidth = 24

# Custom ASCII Art
# This should be an array of strings, with positive
# height and width equal to $imgwidth defined above.
# $CustomAscii = @(
#     "⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣦⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣶⣶⣾⣷⣶⣆⠸⣿⣿⡟⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣷⡈⠻⠿⠟⠻⠿⢿⣷⣤⣤⣄⠀⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠈⠻⣿⣿⣦⠀ ⠀"
#     "⠀⠀⠀⢀⣤⣤⡘⢿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿⡇ ⠀"
#     "⠀⠀⠀⣿⣿⣿⡇⢸⣿⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢈⣉⣉⡁ ⠀"
#     "⠀⠀⠀⠈⠛⠛⢡⣾⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⡇ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠻⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⠟⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⡿⢁⣴⣶⣦⣴⣶⣾⡿⠛⠛⠋⠀⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠿⠿⢿⡿⠿⠏⢰⣿⣿⣧⠀⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⠟⠀⠀ ⠀"
# )

# Make the logo blink
# $blink = $true

# Display all built-in info segments.
# $all = $true

# Add a custom info line
function info_custom_time {
     return @{
        title = "Now"
        content = (Get-Date -Format "d/M/yyyy, H:mm:ss")
    }
}

function info_meteoBrugine {
    if ($PSVersionTable.PSVersion.Major -gt 5) {
        return @{
            title = "Weather"
            content = (Invoke-WebRequest 'http://wttr.in/Brugine?format=4' -UserAgent 'curl').Content.Trim()
        }
    }
}

function info_meteoOderzo {
    if ($PSVersionTable.PSVersion.Major -gt 5) {
        return @{
            title = "Weather"
            content = (Invoke-WebRequest 'http://wttr.in/Oderzo?format=4').Content.Trim()
        }
    }
}

function info_meteoLorenzago {
    if ($PSVersionTable.PSVersion.Major -gt 5) {
        return @{
            title = "Weather"
            content = (Invoke-WebRequest 'http://wttr.in/Lorenzago?format=4').Content.Trim()
        }
    }
}


# Configure which disks are shown
$ShowDisks = @("C:", "G:")
# $ShowDisks = @("*") # Show all available disks

# Configure which package managers are shown
# disabling unused ones will improve speed
$ShowPkgs = @("")

# Use the following option to specify custom package managers.
# Create a function with that name as suffix, and which returns
# the number of packages. Two examples are shown here:
# $CustomPkgs = @("cargo", "just-install")
# function info_pkg_cargo {
#     return (cargo install --list | Where-Object {$_ -like "*:" }).Length
# }
# function info_pkg_just-install {
#     return (just-install list).Length
# }

# Configure how to show info for levels
# Default is for text only.
# 'bar' is for bar only.
# 'textbar' is for text + bar.
# 'bartext' is for bar + text.
$cpustyle = 'bartext'
$memorystyle = 'bartext'
$diskstyle = 'bartext'
$batterystyle = 'bartext'


# Remove the '#' from any of the lines in
# the following to **enable** their output.

@(
    "title"
    "dashes"
    "os"
    "computer"
    # "kernel"
    # "motherboard"
    "custom_time"  # use custom info line
    "uptime"
    # "pwsh"
    "resolution"
    "terminal"
    "cpu"
    "gpu"
    # "cpu_usage"  # takes some time
    "memory"
    "disk"
    "battery"
    # "locale"
    # "weather"
    "local_ip"
    "public_ip"
    "blank"
    "meteoBrugine"
    "meteoOderzo"
    "meteoLorenzago"
    "blank"
    "colorbar"
)
