# compilation from partial scripts
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider NuGet -MinimumVersion '2.8.5.208' -Force # установка пакета Nuget
# регистрация репозиториев
# Register-PSRepository -Name MSPSGallery -SourceLocation "http://www.microsoft.com/"; -InstallationPolicy Trusted
# Register-PSRepository -Name PSGallery -SourceLocation "https://msconfiggallery.cloudapp.net/api/v2/"; -PackageManagementProvider NuGet -InstallationPolicy Trusted
#Set-PSRepository -Name "MSPSGallery" -InstallationPolicy Trusted
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted


# поиск модуля и установка  модуля
#Find-Module | ? { $_. name -match "PSwindowsupdate" } | Install-Module -Verbose
#Find-Module | ? { $_. name -match "xSqlServer" } #| Install-Module -Verbose
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

$cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'DscEncryptionCert' -HashAlgorithm SHA256
$thumbprint = $cert.thumbprint
$filepath = "C:\DSCPlay\ADDeploy\SelfSigned.cer"
$outputpath = 'C:\DSCPlay\ADDeploy'
Export-Certificate -Cert $cert -FilePath $filepath



$domainName = 'testground.lab'
$domainNetbiosName = 'testground'

$domainAdminName = 'groot'
$domainAdminPwd  = ConvertTo-SecureString 'P@ssw0rd2020$' -AsPlainText -Force 
$domainAdminCred  = New-Object System.Management.Automation.PSCredential ($domainAdminName,$domainAdminPwd)

$SafeModeAdminName = 'administrator'
$SafeModeAdminPwd  = ConvertTo-SecureString 'P@ssw0rd$' -AsPlainText -Force
$SafeModeAdminCred  = New-Object System.Management.Automation.PSCredential ($SafeModeAdminName,$SafeModeAdminPwd)

cd 'C:\DSCPlay'
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