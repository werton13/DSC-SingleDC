# compilation from partial scripts
param (

    [parameter(mandatory=$true)]
    [string]$domainname,
    [parameter(mandatory=$true)]
    [string]$DomainNetbiosName,
    [parameter(mandatory=$true)]
    [string]$SafeModeAdminPassword,
    [parameter(mandatory=$true)]
    [string]$DomainAdminPassword,
    [parameter(mandatory=$true)]
    [string]$DSCFolder
    )


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider NuGet -MinimumVersion '2.8.5.208' -Force # установка пакета Nuget
# регистрация репозиториев
# Register-PSRepository -Name MSPSGallery -SourceLocation "http://www.microsoft.com/"; -InstallationPolicy Trusted
# Register-PSRepository -Name PSGallery -SourceLocation "https://msconfiggallery.cloudapp.net/api/v2/"; -PackageManagementProvider NuGet -InstallationPolicy Trusted
#Set-PSRepository -Name "MSPSGallery" -InstallationPolicy Trusted
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted


# поиск модуля и установка  модуля

Install-module -Name xComputermanagement -Force
Install-module -Name xPendingReboot -Force
Install-Module -Name xActiveDirectory -Force

[DscLocalConfigurationManager()]
configuration LCMCOnfig {
    Node localhost {
        settings {
            ConfigurationMode = 'ApplyandAutoCorrect'
            RebootNodeIfNeeded = $true
            RefreshFrequencyMins = 30
            ActionAfterReboot = 'ContinueConfiguration'
            }
    }
}

$LCMCOnfigPath = mkdir 'c:\ADDeploy\LCMConfig'
LCMCOnfig -outputpath  $LCMCOnfigPath 

Set-DscLocalConfigurationManager -path $LCMCOnfigPath -force

mkdir "$DSCFolder\ADDeploy"
$cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'DscEncryptionCert' -HashAlgorithm SHA256
$thumbprint = $cert.thumbprint
$filepath = "$DSCFolder\ADDeploy\SelfSigned.cer"
$outputpath = "$DSCFolder\ADDeploy"
Export-Certificate -Cert $cert -FilePath $filepath



$domainName = $domainname
$domainNetbiosName = $DomainNetbiosName

$domainAdminName = 'groot'
$domainAdminPwd  = $DomainAdminPassword
$domainAdminCred  = New-Object System.Management.Automation.PSCredential ($domainAdminName,$domainAdminPwd)

$SafeModeAdminName = 'administrator'
$SafeModeAdminPwd  = $SafeModeAdminPassword
$SafeModeAdminCred  = New-Object System.Management.Automation.PSCredential ($SafeModeAdminName,$SafeModeAdminPwd)

#cd "$DSCFolder"
cd $DSCFolder\$(gci -path $DSCFolder | ?{$_ -match "DSC" -and $_ -notmatch ".zip"})

. ./ADSingleDCConfig.ps1
#./ADSingleDCConfig.ps1
<# CreateNewADDOmain -domainname $domainName `
                  -domainnetbiosname $domainNetbiosName  `
                  -SafeModeAdminCred $SafeModeAdminCred `
                  -DomainAdminCred $domainAdminCred `
                  -outputpath 'C:\DSCPlay\ADDeploy'

#>
$cd = @{

AllNodes = @(

        @{
          NodeName = "localhost"
          CertificateFile = $filepath
          Thumbprint = $thumbprint
          }
          )
}
CreateNewADDOmain -ConfigurationData $cd `
                  -certthumbprint  $thumbprint `
                  -domainname $domainName `
                  -domainnetbiosname $domainNetbiosName  `
                  -SafeModeAdminCred $SafeModeAdminCred `
                  -DomainAdminCred $domainAdminCred `
                  -outputpath $outputpath

Set-DscLocalConfigurationManager -path $outputpath -force
start-dscconfiguration -path $outputpath -force
