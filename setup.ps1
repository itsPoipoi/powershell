$env:DOCUMENTS = [Environment]::GetFolderPath("MyDocuments")
curl -sL https://raw.githubusercontent.com/itsPoipoi/powershell/refs/heads/main/Microsoft.PowerShell_profile.ps1 -o "$env:DOCUMENTS\PowerShell\Microsoft.PowerShell_profile.ps1" --create-dirs
& $profile
