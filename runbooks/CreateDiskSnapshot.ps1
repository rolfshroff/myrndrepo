<#
    .DESCRIPTION
        An example runbook which gets all the ARM resources using the Run As Account (Service Principal)

    .NOTES
        AUTHOR: Azure Automation Team
        LASTEDIT: Mar 14, 2016
#>

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

foreach ($disk in Get-AzDisk) { 
    foreach ($tag in $disk.Tags) { 
        if ($tag.Snapshot -eq 'True') { 
            Write-Output $disk

            $snapshotconfig = New-AzSnapshotConfig -SourceUri $disk.Id -CreateOption Copy -Location $disk.Location -AccountType 'Standard_LRS'
            $timestampToAppend = ([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'AUS Eastern Standard Time')).ToString('yyyyMMdd.HHmm')
            $snapshotName = $disk.Name + '_' + $timestampToAppend
            
            "Creating snapshot for disk [$($disk.Name)] at [$timestampToAppend] with name [$snapshotName]"
            $snapshot = New-AzSnapshot -Snapshot $snapshotconfig -SnapshotName $snapshotName -ResourceGroupName $disk.ResourceGroupName
            $snapshot.Tags = $disk.Tags
            Update-AzSnapshot -SnapshotName $snapshot.Name -ResourceGroupName $snapshot.ResourceGroupName -Snapshot $snapshot
        } 
    } 
}
