function _validate6PTR () {
	[Cmdletbinding()]
	Param([Parameter(Mandatory=$true)][System.Object]$6PTRResult)
	if ($6PTRResult.Type -eq 'SOA') {
		Write-Verbose "[$($MyInvocation.MyCommand.Name)] DNS server returned an SOA record, no AAAA record found. Bailing out."
		throw 'AAAA record not found'
	}
}
<#
.SYNOPSIS
	Display common DNS records for a given hostname, IPv4 & IPv6 by default
.DESCRIPTION
	Allow a human to quickly get all of the common results for a hostname.
.PARAMETER skip6
	You may optionally skip IPv6
.PARAMETER skip4
	You may optionally skip IPv4
.EXAMPLE
	get-DnsCommonRecords google.com
	Name                           Value
	----                           -----
	A                              172.217.1.238
	APTR                           {lax17s02-in-f14.1e100.net, dfw25s25-in-f14.1e100.net}
	AAAA                           2607:f8b0:4000:80e::200e
	AAAAPTR                        dfw25s25-in-x0e.1e100.net
#>
function get-DnsCommonRecords (){
	[Cmdletbinding()]
	Param(
		[Parameter(Mandatory=$true)][string]$hostname,
		[Parameter(Mandatory=$false)][switch]$skip6,
		[Parameter(Mandatory=$false)][switch]$skip4
	)
	$Results=[ordered]@{}
	if (!($skip4)) {
		try {
			[array]$AResult=(Resolve-DnsName -Name $hostname -Type A -ErrorAction Stop).IPAddress
			#if ($AResult.Count -gt 1) {Write-Warning "[$($MyInvocation.MyCommand.Name)] This A record has multiple results, only processing PTR record for the first result" }
			$Results.Add('A',$AResult)
			$PTRResults=@()
			foreach($item in $AResult) {
				try {$itemResult=(Resolve-DnsName -Name $item -Type PTR -ErrorAction Stop).NameHost}
				catch {Write-Warning "Pointer $item could not be resolved to a hostname"}
				$PTRResults+=$itemResult
			}
			$Results.Add('APTR',$PTRResults)
		}
		catch {
			Write-Error $Error[0].Exception.Message
		}
	}
	if (!($skip6)){
		try {
			[array]$AAAAResult=(Resolve-DnsName -Name $hostname -Type AAAA -ErrorAction Stop).IPAddress
			#if ($AAAAResult.Count -gt 1) {Write-Warning "[$($MyInvocation.MyCommand.Name)] This AAAA record has multiple results, only processing PTR record for the first result" }
			$Results.Add('AAAA',$AAAAResult)
			$PTR6Results=@()
			foreach ($6item in $AAAAResult) {
				try {
					$6itemResult=Resolve-DnsName -Name $6item -Type PTR -ErrorAction Stop
					_validate6PTR($6itemResult)
				} 
				catch {
					Write-Warning "Could not resolve pointer $6item to a hostname"
					continue
				}
				$PTR6Results+=$6itemResult.NameHost
				
				#try {$PTR6Results=Resolve-DnsName -Name $item -Type PTR -ErrorAction Stop} catch {throw 'Record not resolved'}
				#try {_validate6PTR($6item)} catch {throw 'Record not resolved'}
				#try {$PRT6Results+=(Resolve-DnsName -Name $item -Type PTR -ErrorAction Stop).NameHost}
				#catch {Write-Warning "Pointer $item6 could not be resolved to a hostname"}
			}
			$Results.Add('AAAAPTR',$PTR6Results)
		}
		catch {
			Write-Error $Error[0].Exception.Message
		}
	}
	$Results
}
function test-ForwardDNSRecords {
	[Cmdletbinding()]
	Param(
		[Parameter(Mandatory=$true)][string]$hostname,
		[Parameter(Mandatory=$false)][switch]$passthru,
		[Parameter(Mandatory=$false)][switch]$skip6,
		[Parameter(Mandatory=$false)][switch]$skip4
	)
	$Results=[ordered]@{}
	try {
		if (!($skip4)) {
			Write-Verbose "[$($MyInvocation.MyCommand.Name)] Trying to get 'A' results for:"
			$AResult=Resolve-DnsName -Name $hostname -Type A -ErrorAction Stop 
			Write-Verbose "[$($MyInvocation.MyCommand.Name)] Found A record: $($AResult.IPAddress)"
			$Results.Add('A',$AResult.IPAddress)
		}
		if (!($skip6)) {
			Write-Verbose "[$($MyInvocation.MyCommand.Name)] Trying to get 'AAAA' results for:"
			$AAAAResult=Resolve-DnsName -Name $hostname -Type AAAA -ErrorAction Stop
			_validate6PTR($AAAAResult)
			Write-Verbose "[$($MyInvocation.MyCommand.Name)] Found AAAA record: $($AAAAResult.IPAddress)"
			$Results.Add('AAAA',$AAAAResult.IPAddress)
		}
		if ($passthru) {
			Write-Verbose "[$($MyInvocation.MyCommand.Name)] Passthru requested, emitting dns results"
			$Results
		}
		else {$true}
	}
	catch {
		$false
	}
}
function test-ReverseDNSRecords {
	[Cmdletbinding()]
	Param(
		[Parameter(Mandatory=$true)][string]$hostname,
		[Parameter(Mandatory=$false)][switch]$passthru,
		[Parameter(Mandatory=$false)][switch]$skip6,
		[Parameter(Mandatory=$false)][switch]$skip4
	)
	Write-Verbose "[$($MyInvocation.MyCommand.Name)] Attempting to get Forward DNS results."
	$ForwardResults=Test-ForwardDNSRecords $hostname -passthru -skip4:$skip4 -skip6:$skip6
	if (!$ForwardResults) {
		Write-Verbose "[$($MyInvocation.MyCommand.Name)] Failed getting A & AAAA records, bailing out."
		$false
		break
	}
	
	$Results=[ordered]@{}
	try {
		if (!($skip4)) {
			$v4Results=@()
			Write-Verbose "[$($MyInvocation.MyCommand.Name)] Trying to get 'IPv4 PTR' results"
			foreach($item in [array]$ForwardResults['A']) {
				try {$v4Results+=Resolve-DnsName -Name $item -Type PTR -ErrorAction Stop} catch {
					return $false
				}
			}
			$Results.Add('v4',$v4Results.NameHost)
		}
		if (!($skip6)) {
			$v6Results=@()
			Write-Verbose "[$($MyInvocation.MyCommand.Name)] Trying to get 'IPv6 PTR' results"
			foreach($item in [array]$ForwardResults['AAAA']) {
				try {$v6Results+=Resolve-DnsName -Name $item -Type PTR -ErrorAction Stop } catch {continue}
			}

			$Results.Add('v6',$v6Results.NameHost)
		}

		if ($passthru) {
			Write-Verbose "[$($MyInvocation.MyCommand.Name)] Passthru requested, emitting dns results"
			$Results
		}
		else {$true}
	}
	catch {
		$false
	}
}