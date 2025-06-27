Clear-Host

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")

if (-not $isAdmin) {
    Write-Warning "Reopen powershell with admin rights"
    exit 1
}

Write-Host @"
       
888                        888
888                        888
888                        888
88888b.   .d88b.  .d8888b  888888 .d8888b
888 "88b d88""88b 88K      888    88K
888  888 888  888 "Y8888b. 888    "Y8888b.
888  888 Y88..88P      X88 Y88b.       X88
888  888  "Y88P"   88888P'  "Y888  88888P'  
                             
    - Hosts by MALWARE
    - Autoinstaller by lyelly

"@

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$commitsApiUrl = "https://api.github.com/repos/ImMALWARE/textbin/commits?path=hosts&per_page=1"
$rawUrl = "https://raw.githubusercontent.com/ImMALWARE/textbin/refs/heads/main/hosts"
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$processSuccess = $true

function Print-Message {
    param (
        [string]$status,
        [string]$message
    )

    $color = switch ($status) {
        "[*]" { "White" }
        "[+]" { "Green" }
        "[!]" { "Red" }
        default { "Gray" }
    }

    Write-Host "$status $message" -ForegroundColor $color
}

Print-Message "[*]" "Starting process"
Print-Message "[*]" "Fetching last update date"

try {
    $commitResponse = Invoke-WebRequest -Uri $commitsApiUrl -UseBasicParsing -Headers @{ "User-Agent" = "PowerShellScript" }
    $commitJson = $commitResponse.Content | ConvertFrom-Json

    if ($commitJson.Length -gt 0) {
        $lastCommitDateRaw = $commitJson[0].commit.committer.date
        $lastCommitDate = [DateTime]::Parse($lastCommitDateRaw).ToLocalTime()
        Print-Message "[+]" "Last update at: $lastCommitDate"
    }
    else {
        Print-Message "[!]" "No date found."
        $processSuccess = $false
    }

    if ($processSuccess) {
        Print-Message "[*]" "Downloading hosts content"
        $response = Invoke-WebRequest -Uri $rawUrl -UseBasicParsing

        if ($response.StatusCode -eq 200) {
            Print-Message "[+]" "Content downloaded successfully."

            Print-Message "[*]" "Creating backup of current hosts file"
            Copy-Item -Path $hostsPath -Destination "$hostsPath.bak" -Force
            Print-Message "[+]" "Backup created: hosts.bak"

            Print-Message "[*]" "Updating hosts file"
            $utf8 = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($hostsPath, $response.Content, $utf8)

            Print-Message "[*]" "Location: $hostsPath"
            Print-Message "[+]" "Process completed successfully!"
        }
        else {
            Print-Message "[!]" "Failed to download hosts file. Status code: $($response.StatusCode)"
            $processSuccess = $false
        }
    }
}
catch {
    Print-Message "[!]" "Error: $($_.Exception.Message)"
    $processSuccess = $false
}

if (-not $processSuccess) {
    Print-Message "[!]" "Process failed!"
}

Write-Host ""

Write-Host "Press any key to continue..."
[void][System.Console]::ReadKey($true)

Clear-Host
