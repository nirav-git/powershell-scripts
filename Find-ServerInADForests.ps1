# Searches for server computer objects across all trusted AD domains/forests

$servers = @("SERVER_NAME")

$domains = Get-ADTrust -Filter * | ForEach-Object { Get-ADDomain -Identity $_.Target }
$domains += Get-ADDomain -Current LoggedOnUser

ForEach ($server in $servers) {
    ForEach ($domain in $domains) {
        $ADMatch = Get-ADComputer -Filter "Name -eq '$($server)'" -Server $domain.Forest -ErrorAction SilentlyContinue
        If ($ADMatch) {
            Write-Host "$($ADMatch.DNSHostName)"
            Break
        }
    }
}
