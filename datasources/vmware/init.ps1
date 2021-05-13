if (!(Get-Module vmware* -ListAvailable)){
    Install-Module -Name VMware.PowerCLI -AllowClobber -Scope CurrentUser
    Import-Module VMware.PowerCLI
}
else { Import-Module Vmware.PowerCLI }

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false |out-null
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false |Out-Null

try {Get-Variable config -ErrorAction Stop|Out-Null}
catch {. $PSScriptRoot\..\..\config.ps1}

Write-Host 'To save your password encrypted on your local machine, modify the following line as needed:'
Write-Host "New-VICredentialStoreItem -host `"$($config.VcenterHostName)`" -user `"ExampleUserName`" -password `"ExamplePassword`""

try { Get-ViRole -ErrorAction SilentlyContinue | Out-Null }
catch {
    Connect-VIServer -server $config.VcenterHostName -Protocol https -InformationAction SilentlyContinue |out-null
}