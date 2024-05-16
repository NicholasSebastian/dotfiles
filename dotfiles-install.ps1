# Written by Nicholas Sebastian on May 2024.

# NOTE: If permission to run .ps1 scripts is denied, run the following command:
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted

# Install some apps.
Write-Output "Installing some apps..."
winget install -e --id Google.Chrome
winget install -e --id Mozilla.Firefox.ESR
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id Discord.Discord
winget install -e --id WhatsApp.WhatsApp
winget install -e --id LINE.LINE
winget install -e --id Telegram.TelegramDesktop
winget install -e --id Valve.Steam
winget install -e --id Spotify.Spotify
winget install -e --id VideoLAN.VLC
winget install -e --id OBSProject.OBSStudio
winget install -e --id dotPDNLLC.paintdotnet
winget install -e --id KDE.Krita
winget install -e --id BlenderFoundation.Blender
winget install -e --id Figma.Figma
winget install -e --id WinSCP.WinSCP
winget install -e --id Docker.DockerDesktop
winget install -e --id Mojang.MinecraftLauncher
winget install -e --id GeekUninstaller.GeekUninstaller

# Patch Spotify with Spicetify.
Invoke-WebRequest -useb https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1 | Invoke-Expression

# Install Chocolatey.
Write-Output "Installing Chocolatey..."
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Enable some optional windows features.
try {
    Write-Output "Enabling some Windows features..."
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
}
catch {
    Write-Output "Cannot enable some features..."
}

# Install WSL.
Write-Output "Installing Windows Subsystem for Linux..."
wsl --install -d Ubuntu-24.04

# Check if FiraCode Nerd Fonts is installed.
if (Test-Path "C:\Windows\Fonts\FiraCodeNerdFont*")
{
    Write-Output "Fira Code Nerd Fonts already installed."
}
else
{
    Write-Output "Installing FiraCode Nerd Fonts..."

    # Download FiraCode Nerd Fonts.
    $FontRepository = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.1/FiraCode.zip"
    $FontZip = "$env:USERPROFILE\Downloads\FiraCode.zip"
    Invoke-WebRequest $FontRepository -OutFile $FontZip

    # Unzip the Fonts.
    $FontFolder = "$env:USERPROFILE\Downloads\FiraCode"
    Expand-Archive $FontZip -DestinationPath $FontFolder

    # Install the Fonts.
    $FontItem = Get-Item -Path $FontFolder
    $FontList = Get-ChildItem -Path "$FontItem\*" -Include ('*.fon','*.otf','*.ttc','*.ttf') -Recurse
    foreach ($Font in $FontList) {
        Copy-Item $Font "C:\Windows\Fonts"
        New-ItemProperty -Name $Font.BaseName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $Font.name
    }
}

# Install Oh My Posh.
Write-Output "Installing Oh My Posh..."
winget install JanDeDobbeleer.OhMyPosh -s winget

# A hack to refresh the environment variables without having to restart the terminal.
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

# Configure Oh My Posh to run when Powershell starts.
Add-Content -Path $PROFILE -Value "oh-my-posh init pwsh | Invoke-Expression"

# Install Terminal Icons.
Write-Output "Installing Terminal Icons..."
Install-Module -Name Terminal-Icons -Repository PSGallery
Import-Module Terminal-Icons

# Install winfetch.
Write-Output "Installing some packages..."
Install-Module z -Force -AllowClobber
Install-Script winfetch -Force

# Install Powershell autocomplete.
Install-Module PSReadLine -Force -SkipPublisherCheck
Add-Content -Path $PROFILE -Value "Set-PSReadLineOption -PredictionSource History"
Add-Content -Path $PROFILE -Value "Set-PSReadLineOption -PredictionViewStyle ListView"

# Define a custom 'which' command.
Add-Content -Path $PROFILE -Value @"
function which(`$command) {
    Get-Command -Name `$command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}
"@

# Create a symbolic link to the Projects folder in WSL from Windows.
$HomeDir = "\\wsl.localhost\Ubuntu-24.04\home"
$User = Get-ChildItem -Path $HomeDir -Recurse | Select-Object -First 1
$ProjectsDir = $HomeDir + "\" + $User + "\Projects"
mkdir $ProjectsDir
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\Projects" -Target $ProjectsDir

# Notes.
Write-Output "Only some of your favourite apps have been installed."
Write-Output "Don't forget to install the apps yet to be installed yourself, such as Godot and Vencord."
Write-Output "Don't forget to run 'spicetify update' whenever Spotify updates in case of breaking changes."
Write-Output "Geek Uninstaller has been installed. Be sure to run it yourself to remove any bloatware."
