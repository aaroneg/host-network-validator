if (!(Get-Module vmware* -ListAvailable)){
    Install-Module -Name VMware.PowerCLI -AllowClobber -Scope CurrentUser
    Import-Module VMware.PowerCLI
}
else { Import-Module Vmware.PowerCLI }

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false |out-null

Write-Host 'To save your password encrypted on your local machine, modify the following line as needed:'
Write-Host 'New-VICredentialStoreItem -host "vcenter.fq.dn" -user "ExampleUserName" -password "ExamplePassword"'

try { Get-ViRole -ErrorAction SilentlyContinue | Out-Null }
catch {
    Connect-VIServer -server $config.VcenterHostName -Protocol https -InformationAction SilentlyContinue |out-null
}