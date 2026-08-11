function Show-Banner {
    Write-Host ' ____  ____  __  __ ____   ___   ___   ___  ' -ForegroundColor Cyan
    Write-Host '|  _ \|  _ \|  \/  |___ \ / _ \ / _ \ / _ \ ' -ForegroundColor Cyan
    Write-Host '| |_) | |_) | |\/| | __) | | | | | | | | | |' -ForegroundColor Cyan
    Write-Host '|  _ <|  __/| |  | |/ __/| |_| | |_| | |_| |' -ForegroundColor Cyan
    Write-Host '|_| \_\_|   |_|  |_|_____|\___/ \___/ \___/ ' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '                 Setup PC - ReadyToGo' -ForegroundColor Cyan
    Write-Host ''
}

function Get-File-BitsTransfer {
    param (
        [string]$Url,
        [string]$Destination
    )
    try {
        Start-BitsTransfer -Source $Url -Destination $Destination -ErrorAction Stop
        Write-Host "Download completato: $Destination"
        return $true
    }
    catch {
        Write-Host "Errore nel download $Url. Verifica l'URL o la connessione. $($_.Exception.Message)"
        return $false
    }
}

function Get-File-WebRequest {
    param (
        [string]$Url,
        [string]$Destination
    )
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination -ErrorAction Stop
        Write-Host "Download completato: $Destination"
        return $true
    }
    catch {
        Write-Host "Errore nel download $Url. Verifica l'URL o la connessione. $($_.Exception.Message)"
        return $false
    }
}

function Test-DownloadedFile {
    param (
        [string]$Path,
        [string]$ExpectedSha256 = ""
    )

    if (-not (Test-Path $Path)) {
        Write-Host "File non trovato per la verifica: $Path"
        return $false
    }

    $fileInfo = Get-Item $Path
    if ($fileInfo.Length -eq 0) {
        Write-Host "File vuoto, download probabilmente fallito: $Path"
        return $false
    }

    # Controllo header MZ: evita di eseguire pagine di errore/HTML salvate con estensione .exe
    $header = [byte[]]::new(2)
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $stream.Read($header, 0, 2) | Out-Null
    }
    finally {
        $stream.Close()
    }
    if (-not ($header[0] -eq 0x4D -and $header[1] -eq 0x5A)) {
        Write-Host "Il file scaricato non sembra un eseguibile valido (header MZ assente): $Path"
        return $false
    }

    $hash = (Get-FileHash -Path $Path -Algorithm SHA256).Hash
    Write-Host "SHA256 di $($fileInfo.Name): $hash"

    if ($ExpectedSha256 -ne "") {
        if ($hash -ne $ExpectedSha256.ToUpper()) {
            Write-Host "ATTENZIONE: hash non corrispondente per $Path (attesa: $ExpectedSha256, calcolata: $hash). Installazione annullata."
            return $false
        }
        Write-Host "Hash verificato correttamente."
    }
    else {
        Write-Host "Hash non pinnato per questo file (URL a versione dinamica) - verifica manuale consigliata."
    }

    return $true
}

function Install-Software {
    param (
        [string]$Path,
        [string]$ArgumentList = "/silent"
    )
    try {
        $process = Start-Process -FilePath $Path -ArgumentList $ArgumentList -Wait -PassThru -ErrorAction Stop
        if ($process.ExitCode -eq 0) {
            Write-Host "Installazione completata: $Path"
            return $true
        }
        else {
            Write-Host "Installazione terminata con codice di uscita $($process.ExitCode): $Path"
            return $false
        }
    }
    catch {
        Write-Host "Errore nell'installazione $Path. $($_.Exception.Message)"
        return $false
    }
}

function Invoke-Winget {
    param (
        [string[]]$Arguments,
        [string]$Description
    )
    & winget @Arguments
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$Description completata."
        return $true
    }
    else {
        Write-Host "$Description terminata con codice di uscita $LASTEXITCODE."
        return $false
    }
}

function Set-AdministratorPriviliges {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}

# Show ASCII banner at startup
Show-Banner

# Request the Administrator privileges
Set-AdministratorPriviliges

# Install WinGet
try {
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
    Write-Host "WinGet registrato/verificato correttamente."
}
catch {
    Write-Host "Errore nella registrazione di WinGet. $($_.Exception.Message)"
}

$installCPUSoftware = Read-Host "Vuoi installare Intel Driver Support Assistant/No? (S/N)" # Ask to the User if he wants to install CPU Software

$InstallQuickHeal = Read-Host "Vuoi installare Quick Heal Antivirus Pro? (S/N)" # Ask to the User if he wants to install Quick Heal Antivirus Pro

$installLibreOffice = Read-Host "Vuoi installare LibreOffice? (S/N)" # Ask to the User if he wants to install LibreOffice

$installProductSoftware = Read-Host "Vuoi installare il software del produttore? (S/N)" # Ask to the User if he wants to install Product Software

# Beginning of the installation process
Write-Host "Inizio installazione processi..."

# Prompt for acceptance of msstore terms
Write-Host "Aggiornamento origine del Microsoft Store. Potrebbe essere richiesto di accettare i termini."
Pause
Invoke-Winget -Arguments @("source", "update", "--name", "msstore", "--accept-package-agreements") -Description "Aggiornamento origine msstore"

if ($installProductSoftware -eq "S") {
    $productName = Read-Host "Nome del produttore? (ASUS/Dell/HP/Lenovo)"

switch ($productName.ToLower()) {
    "dell" {
        Write-Host "Download e installazione di Dell SupportAssist..."
        $Url = "https://downloads.dell.com/serviceability/catalog/SupportAssistInstaller.exe"
        $Destination = [System.IO.Path]::Combine([System.IO.Path]::Combine($env:USERPROFILE, 'Downloads'), 'DellSupportAssistInstaller.exe')

        if (Get-File-BitsTransfer -Url $Url -Destination $Destination) {
            if (Test-DownloadedFile -Path $Destination) {
                Install-Software -Path $Destination
            }
        }
    }

    "hp" {
        Write-Host "Download e installazione di HP Support Assistant..."
        $Url = "https://ftp.hp.com/pub/softpaq/sp155001-155500/sp155262.exe"
        $Destination = [System.IO.Path]::Combine([System.IO.Path]::Combine($env:USERPROFILE, 'Downloads'), 'HPSupportAssistantInstaller.exe')

        if (Get-File-BitsTransfer -Url $Url -Destination $Destination) {
            if (Test-DownloadedFile -Path $Destination) {
                Unblock-File -Path $Destination
                Install-Software -Path $Destination
            }
        }
    }

    "asus" {
        Write-Host "Installazione di MyASUS tramite Microsoft Store..."

        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Invoke-Winget -Arguments @("install", "--id", "9N7R5S6B0ZZH", "--source", "msstore", "--accept-package-agreements", "--accept-source-agreements") -Description "Installazione MyASUS"
        }
        else {
            Write-Host "Winget non disponibile. Apertura Microsoft Store..."
            Start-Process "ms-windows-store://pdp/?ProductId=9N7R5S6B0ZZH"
        }
    }

    "lenovo" {
        Write-Host "Installazione di Lenovo Vantage tramite Microsoft Store..."

        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Invoke-Winget -Arguments @("install", "--id", "9WZDNCRFJ4MV", "--source", "msstore", "--accept-package-agreements", "--accept-source-agreements") -Description "Installazione Lenovo Vantage"
        }
        else {
            Write-Host "Winget non disponibile. Apertura Microsoft Store..."
            Start-Process "ms-windows-store://pdp/?ProductId=9WZDNCRFJ4MV"
        }
    }

    default {
        Write-Host "Nome non riconosciuto, installazione saltata."
    }
}
}
else {
    Write-Host "Installazione del software del produttore saltata."
}

# Download the file for Assistenza RPM2000
Write-Host "Download Assistenza RPM2000..."

$RPM2000Url = "https://rpm2000.it/Assistenza%20RPM2000.exe"
$RPM2000Destination = [System.IO.Path]::Combine([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop'), 'Assistenza RPM2000.exe')

if (Get-File-BitsTransfer -Url $RPM2000Url -Destination $RPM2000Destination) {
    Test-DownloadedFile -Path $RPM2000Destination | Out-Null
}

# Install Adobe Acrobat Reader DC
Write-Host "Installazione Adobe Acrobat Reader DC..."
Invoke-Winget -Arguments @("install", "--id", "Adobe.Acrobat.Reader.64-bit", "-e", "--source", "winget", "--silent", "--accept-package-agreements") -Description "Installazione Adobe Acrobat Reader DC"

# Install Mozilla Firefox
Write-Host "Installazione Mozilla Firefox..."

$FirefoxUrl = "https://download.mozilla.org/?product=firefox-stub&os=win&lang=it"
$FirefoxInstallerDestination = [System.IO.Path]::Combine([System.IO.Path]::Combine($env:USERPROFILE, 'Downloads'), 'FirefoxInstaller.exe')

if (Get-File-BitsTransfer -Url $FirefoxUrl -Destination $FirefoxInstallerDestination) {
    if (Test-DownloadedFile -Path $FirefoxInstallerDestination) {
        Install-Software -Path $FirefoxInstallerDestination
    }
}

# Install Google Chrome
Write-Host "Installazione Google Chrome..."
Invoke-Winget -Arguments @("install", "--id", "Google.Chrome", "-e", "--source", "winget", "--silent", "--accept-package-agreements") -Description "Installazione Google Chrome"

# Check if CPU Software should be installed
if ($installCPUSoftware -eq "S") {
    Write-Host "Download e installazione Intel Driver Support Assistant..."
    Invoke-Winget -Arguments @("install", "--id", "Intel.IntelDriverAndSupportAssistant", "-e", "--source", "winget", "--silent", "--accept-package-agreements") -Description "Installazione Intel Driver Support Assistant"
}
else {
    Write-Host "Installazione del software del processore saltata."
}

# Check if LibreOffice should be installed
if ($installLibreOffice -eq "S") {
    # Install LibreOffice
    Write-Host "Installazione LibreOffice..."
    Invoke-Winget -Arguments @("install", "--id", "TheDocumentFoundation.LibreOffice", "-e", "--source", "winget", "--silent", "--accept-package-agreements") -Description "Installazione LibreOffice"
}
else {
    Write-Host "Installazione di LibreOffice saltata."
}

# Check if Quick Heal Antivirus Pro should be installed
if ($InstallQuickHeal -eq "S") {
    Write-Host "Download e installazione Quick Heal Antivirus Pro..."
    $Url = "https://download.quickheal.com/builds/2400/av/italy/QHAV.EXE"
    $QuickHealInstallerDestination = [System.IO.Path]::Combine([System.IO.Path]::Combine($env:USERPROFILE, 'Downloads'), 'QuickHealAntivirusProInstaller.exe')

    if (Get-File-BitsTransfer -Url $Url -Destination $QuickHealInstallerDestination) {
        if (Test-DownloadedFile -Path $QuickHealInstallerDestination) {
            Install-Software -Path $QuickHealInstallerDestination
        }
    }
}
else {
    Write-Host "Installazione di Quick Heal Antivirus Pro saltata."
}

# Install VLC Media Player
Write-Host "Installazione VLC Media Player..."
Invoke-Winget -Arguments @("install", "--id", "VideoLAN.VLC", "-e", "--source", "winget", "--silent", "--accept-package-agreements") -Description "Installazione VLC Media Player"

# Install 7-Zip
Write-Host "Installazione 7-Zip..."
Invoke-Winget -Arguments @("install", "--id", "7zip.7zip", "-e", "--source", "winget", "--silent", "--accept-package-agreements") -Description "Installazione 7-Zip"

# End of the process
Write-Host "Installazioni completate."
Pause
