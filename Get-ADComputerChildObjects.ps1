# Retrieves all child AD objects under a computer account in Active Directory

$computerName = "COMPUTER_NAME"
$serverName = "domain.controller.fqdn"

Get-ADComputer -Identity $computerName -Server $serverName | ForEach-Object {
    $childObjects = Get-ADObject -Filter * -SearchBase $_.DistinguishedName -Server $serverName

    $childObjects | ForEach-Object {
        [PSCustomObject]@{
            ComputerName      = $_.Parent.Name
            ChildObjectName   = $_.Name
            ChildObjectType   = $_.ObjectClass
            Description       = $_.Description
            WhenCreated       = $_.WhenCreated
            DistinguishedName = $_.DistinguishedName
        }
    }
}
