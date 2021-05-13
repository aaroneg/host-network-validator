. $PSScriptRoot\init.ps1
$AllVMs = Get-VM
$VMNetInfo = @()
Foreach ($VM in $AllVMs) {
    $VMNetInfo += $VM | Get-NetworkAdapter | ForEach-Object { [PSCustomObject]@{Name = $VM.Name; Adapter = $_.Name; Network = $_.NetworkName; Type = $_.Type; MAC = $_.MacAddress; IPv4 = (($VM.Guest.IPAddress | Where-Object { $_ -notlike '*:*' }) -join ','); IPv6 = (($VM.Guest.IPAddress | Where-Object { $_ -notlike '*.*' }) -join ',') } }
}
$VMNetInfo|Export-Csv $PSScriptRoot\..\..\vmware-data.csv -NoTypeInformation
$VMNetInfo|Export-Clixml $PSScriptRoot\..\..\vmware-data.xml