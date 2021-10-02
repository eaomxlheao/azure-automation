﻿$Creds = Get-AutomationPSCredential -Name 'Creds'
$TenantID = Get-AutomationVariable -Name 'TenantID'

Connect-AzAccount -ServicePrincipal -Credential $Creds -Tenant $TenantID

$vResourceGroupname = "LinkedInLearningAutomation"
$vAutomationAccountName = "LinkedInAutomation"
$vaStorageAccount = Get-AutomationVariable -Name "StorageAccount"


$StartTime = Get-Date
$EndTime = $startTime.AddHours(1.0)
$stgAccount = Get-AzStorageAccount -Name $vaStorageAccount -ResourceGroupName $vResourceGroupname
$SASToken = New-AzStorageAccountSASToken -Service 'Blob' -ResourceType Container,Object -Permission "racwdlup" -startTime $StartTime -ExpiryTime $EndTime -Context $stgAccount.Context
$stgcontext = New-AzStorageContext -storageAccountName $stgAccount.StorageAccountName -SasToken $SASToken

  
try {Import-Module ImportExcel} catch {throw ; return}

$Path = "$env:TEMP\VMDetails.xlsx"
Remove-Item $Path -ErrorAction SilentlyContinue

$blob = Get-AzStorageBlob -Container 'createvms' -Blob 'CreateVM.xlsx' -Context $stgcontext
$tmp = Get-AzStorageBlobContent -CloudBlob $blob.ICloudBlob -Destination $Path -Context $stgcontext #.Context.FileEndPoint + "atcslfileshare"

#import-module psexcel #it wasn't auto loading on my machine

#$details = new-object System.Collections.ArrayList
$ExcelValue = Import-Excel -Path $Path -WorksheetName 'Sheet1' -StartRow 1 -StartColumn 1
#$Data = $ExcelValue | ConvertTo-Json
foreach($vmdetail in $ExcelValue) {
    #$vmdetail
    $VMParameter = @(
            $vmdetail.Name,
            $vmdetail.Computername,
            $vmdetail.Location,
            $vmdetail.RGName,
            $vmdetail.LocalAdminUser,
            $vmdetail.Password,
            $vmdetail.Size,
            $vmdetail.PublisherName,
            $vmdetail.OfferName,
            $vmdetail.SKU
            
    )
    #$VMParameter
        .\CreateVirtualMachineActionRunbook.ps1 $VMParameter
    }
