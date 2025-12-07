# Function to install Nerd Fonts
function Install-NerdFonts {
    param (
        [string]$FontName = "CascadiaCode",
        [string]$FontDisplayName = "CaskaydiaCove NF",
        [string]$Version = "3.2.1"
    )

    try {
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
        if ($fontFamilies -notcontains "${FontDisplayName}") {
            $fontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${Version}/${FontName}.zip"
            $zipFilePath = "$env:TEMP\${FontName}.zip"
            $extractPath = "$env:TEMP\${FontName}"

            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFileAsync((New-Object System.Uri($fontZipUrl)), $zipFilePath)

            while ($webClient.IsBusy) {
                Start-Sleep -Seconds 2
            }

            Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
            $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
            Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf" | ForEach-Object {
                If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                    $destination.CopyHere($_.FullName, 0x10)
                }
            }

            Remove-Item -Path $extractPath -Recurse -Force
            Remove-Item -Path $zipFilePath -Force
        } else {
            Write-Host "Font ${FontDisplayName} already installed"
        }
    }
    catch {
        Write-Error "Failed to download or install ${FontDisplayName} font. Error: $_"
    }
}

# Install Nerd Fonts
$fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
if (-Not ($fontFamilies -contains "CaskaydiaCove NF")) {
    Write-Host "Nerd font not found. Attempting to install..."
    Install-NerdFonts -FontName "CascadiaCode" -FontDisplayName "CaskaydiaCove NF"
    Write-Warning "Don't forget to select the font in your PowerShell profile!"
}

# Ensure Terminal-Icons module is installed
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons

# Admin Check and Prompt Customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# Function to check if a command exists
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

# Editor Configuration
if ($EDITOR_Override){
    $EDITOR = $EDITOR_Override
} else {
    $EDITOR = if (Test-CommandExists nvim) { 'nvim' }
          elseif (Test-CommandExists pvim) { 'pvim' }
          elseif (Test-CommandExists vim) { 'vim' }
          elseif (Test-CommandExists vi) { 'vi' }
          elseif (Test-CommandExists code) { 'code' }
          elseif (Test-CommandExists codium) { 'codium' }
          elseif (Test-CommandExists notepad++) { 'notepad++' }
          elseif (Test-CommandExists sublime_text) { 'sublime_text' }
          else { 'notepad' }
    Set-Alias -Name vim -Value $EDITOR
}

# Function to Update PowerShell
function Update-PowerShell {
    # If function "Update-PowerShell_Override" is defined in profile.ps1 file
    # then call it instead.
    if (Get-Command -Name "Update-PowerShell_Override" -ErrorAction SilentlyContinue) {
        Update-PowerShell_Override;
    } else {
        try {
            Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan
            $updateNeeded = $false
            $currentVersion = $PSVersionTable.PSVersion.ToString()
            $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
            $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
            $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
            if ($currentVersion -lt $latestVersion) {
                $updateNeeded = $true
            }

            if ($updateNeeded) {
                Write-Host "Updating PowerShell..." -ForegroundColor Yellow
                Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
                Write-Host "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
            } else {
                Write-Host "Your PowerShell is up to date." -ForegroundColor Green
            }
        } catch {
            Write-Error "Failed to update PowerShell. Error: $_"
        }
    }
}

# Quick Access to Editing the Profile
function Edit-Profile {
    vim $PROFILE.CurrentUserAllHosts
}
Set-Alias -Name editp -Value Edit-Profile

# Quick Access to Reloading the Profile
function Reload-Profile {
    & $profile
}
Set-Alias -Name relp -Value Reload-Profile

# Open WinUtil full-release
function winutil {
    irm https://christitus.com/win | iex
}

### System Utilities

# Run command as admin
function admin {
    if ($args.Count -gt 0) {
        $argList = $args -join ' '
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command with elevated rights.
Set-Alias -Name su -Value admin

# Create empty file 
function touch($file) { "" | Out-File $file -Encoding ASCII }
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# Unzip
function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}

# grep
function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

# Disk usage
function df {
    get-volume
}

# sed
function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

# which
function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

# pkill and pgrep
function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
    Get-Process $name
}

# Move to Recycle Bin
function trash($path) {
    $fullPath = (Resolve-Path -Path $path).Path

    if (Test-Path $fullPath) {
        $item = Get-Item $fullPath

        if ($item.PSIsContainer) {
          # Handle directory
            $parentPath = $item.Parent.FullName
        } else {
            # Handle file
            $parentPath = $item.DirectoryName
        }

        $shell = New-Object -ComObject 'Shell.Application'
        $shellItem = $shell.NameSpace($parentPath).ParseName($item.Name)

        if ($item) {
            $shellItem.InvokeVerb('delete')
            Write-Host "Item '$fullPath' has been moved to the Recycle Bin."
        } else {
            Write-Host "Error: Could not find the item '$fullPath' to trash."
        }
    } else {
        Write-Host "Error: Item '$fullPath' does not exist."
    }
}

# Flush DNS Cache
function flushdns {
	Clear-DnsClientCache
	Write-Host "DNS has been flushed"
}

# Help Function
function Show-Help {
    $helpText = @"
$($PSStyle.Foreground.Cyan)PowerShell Profile Help$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)Update-PowerShell$($PSStyle.Reset) - Checks for the latest PowerShell release and updates if a new version is available.
$($PSStyle.Foreground.Green)Edit-Profile$($PSStyle.Reset) - Opens the current user's profile for editing using the configured editor.
$($PSStyle.Foreground.Green)Reload-Profile$($PSStyle.Reset) - Reloads the current user's PowerShell profile.


$($PSStyle.Foreground.Cyan)Shortcuts$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)
$($PSStyle.Foreground.Green)df$($PSStyle.Reset) - Displays information about volumes.
$($PSStyle.Foreground.Green)editp$($PSStyle.Reset) - Opens the profile for editing.
$($PSStyle.Foreground.Green)relp$($PSStyle.Reset) - Reloads the profile.
$($PSStyle.Foreground.Green)ff$($PSStyle.Reset) <name> - Finds files recursively with the specified name.
$($PSStyle.Foreground.Green)flushdns$($PSStyle.Reset) - Clears the DNS cache.
$($PSStyle.Foreground.Green)grep$($PSStyle.Reset) <regex> [dir] - Searches for a regex pattern in files within the specified directory or from the pipeline input.
$($PSStyle.Foreground.Green)pgrep$($PSStyle.Reset) <name> - Lists processes by name.
$($PSStyle.Foreground.Green)pkill$($PSStyle.Reset) <name> - Kills processes by name.
$($PSStyle.Foreground.Green)flushdns$($PSStyle.Reset) - Clears the DNS cache.
$($PSStyle.Foreground.Green)sed$($PSStyle.Reset) <file> <find> <replace> - Replaces text in a file.
$($PSStyle.Foreground.Green)touch$($PSStyle.Reset) <file> - Creates a new empty file.
$($PSStyle.Foreground.Green)unzip$($PSStyle.Reset) <file> - Extracts a zip file to the current directory.
$($PSStyle.Foreground.Green)which$($PSStyle.Reset) <name> - Shows the path of the command.
$($PSStyle.Foreground.Green)winutil$($PSStyle.Reset) - Runs the latest WinUtil full-release script from Chris Titus Tech.
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)

Use '$($PSStyle.Foreground.Magenta)Show-Help$($PSStyle.Reset)' to display this help message.
"@
    Write-Host $helpText
}
Write-Host "$($PSStyle.Foreground.Yellow)Use 'Show-Help' to display help$($PSStyle.Reset)"

# Enhanced PowerShell Experience
# Enhanced PSReadLine Configuration
$PSReadLineOptions = @{
    EditMode = 'Windows'
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
    Colors = @{
        Command = '#87CEEB'  # SkyBlue (pastel)
        Parameter = '#98FB98'  # PaleGreen (pastel)
        Operator = '#FFB6C1'  # LightPink (pastel)
        Variable = '#DDA0DD'  # Plum (pastel)
        String = '#FFDAB9'  # PeachPuff (pastel)
        Number = '#B0E0E6'  # PowderBlue (pastel)
        Type = '#F0E68C'  # Khaki (pastel)
        Comment = '#D3D3D3'  # LightGray (pastel)
        Keyword = '#8367c7'  # Violet (pastel)
        Error = '#FF6347'  # Tomato (keeping it close to red for visibility)
    }
    PredictionSource = 'History'
    PredictionViewStyle = 'ListView'
    BellStyle = 'None'
}
Set-PSReadLineOption @PSReadLineOptions

# Install zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
} else {
    Write-Host "zoxide command not found. Attempting to install via winget..."
    try {
        winget install -e --id ajeetdsouza.zoxide
        Write-Host "zoxide installed successfully. Initializing..."
        Invoke-Expression (& { (zoxide init powershell | Out-String) })
    } catch {
        Write-Error "Failed to install zoxide. Error: $_"
    }
}

# Install fzf
if (-Not (Get-Command fzf -ErrorAction SilentlyContinue)) {
    Write-Host "fzf command not found. Attempting to install via winget..."
    try {   
        winget install fzf
        Write-Host "fzf installed successfully."
    } catch {
        Write-Error "Failed to install fzf. Error: $_"
    }
}

# Install fd
if (-Not (Get-Command fd -ErrorAction SilentlyContinue)) {
    Write-Host "fd command not found. Attempting to install via winget..."
    try {   
        winget install fd
        Write-Host "fd installed successfully."
    } catch {
        Write-Error "Failed to install fd. Error: $_"
    }
}

# Set DOCUMENTS env variable
$env:DOCUMENTS = [Environment]::GetFolderPath("MyDocuments")

# Install posh-fzf
$env:Path += ";$env:DOCUMENTS\Powershell\posh-fzf"
if (Get-Command posh-fzf -ErrorAction SilentlyContinue) {
    Invoke-Expression (&posh-fzf init | Out-String)
} else {
    Write-Host "posh-fzf command not found. Attempting to install..."
    try {
        curl -sL -o $env:DOCUMENTS\posh-fzf.zip https://github.com/domsleee/posh-fzf/releases/download/v0.3.0/posh-fzf-v0.3.0-x86_64-pc-windows-msvc.zip
        Expand-Archive -Force -Path "$env:DOCUMENTS\posh-fzf.zip" -DestinationPath "$env:DOCUMENTS\PowerShell\posh-fzf"
        Remove-Item -Path "$env:DOCUMENTS\posh-fzf.zip"
        Write-Host "posh-fzf installed successfully. Initializing..."
        Invoke-Expression (&posh-fzf init | Out-String)
    } catch {
        Write-Error "Failed to install posh-fzf. Error: $_"
    }
}

# Bind Interactive zoxide to CTRL+F
Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -ScriptBlock {
    $fzfSelection = Invoke-PoshFzfStartProcess -FileName "zoxide" -Arguments @("query", "-i") -HeightRowsOrPercent "45%"
    if ($fzfSelection) {
        [Microsoft.PowerShell.PSConsoleReadLine]::DeleteLine()
        Invoke-PoshFzfInsertUtf8("cd $fzfSelection")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}

# Customize the key bindings to your liking
Set-PSReadLineKeyHandler -Key 'Ctrl+t' -ScriptBlock { Invoke-PoshFzfSelectItems }
Set-PSReadLineKeyHandler -Key 'Alt+c' -ScriptBlock { Invoke-PoshFzfChangeDirectory }
Set-PSReadLineKeyHandler -Key 'Ctrl+r' -ScriptBlock { Invoke-PoshFzfSelectHistory }

# Install OMP
if (-Not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Host "oh-my-posh command not found. Attempting to install via winget..."
    try {   
        winget install JanDeDobbeleer.OhMyPosh --source winget
        Write-Host "oh-my-posh installed successfully."
    } catch {
        Write-Error "Failed to install oh-my-posh. Error: $_"
    }
}

## Init OMP with p10k
if (Test-Path $env:DOCUMENTS\PowerShell\powerlevel10k_lean.omp.json) {
    oh-my-posh init pwsh --config "$env:DOCUMENTS\PowerShell\powerlevel10k_lean.omp.json" | Invoke-Expression
} else {
    curl -sL -o $env:DOCUMENTS\PowerShell\powerlevel10k_lean.omp.json https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/powerlevel10k_lean.omp.json
    oh-my-posh init pwsh --config "$env:DOCUMENTS\PowerShell\powerlevel10k_lean.omp.json" | Invoke-Expression
}