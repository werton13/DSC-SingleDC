configuration  CreateNewADDOmain {

    param (
    [parameter(mandatory=$true)]
    [string]$certthumbprint,
    [parameter(mandatory=$true)]
    [string]$domainname,
    [parameter(mandatory=$true)]
    [string]$DomainNetbiosName,
    [parameter(mandatory=$true)]
    [pscredential]$SafeModeAdminCred,
    [parameter(mandatory=$true)]
    [pscredential]$DomainAdminCred
       
    )
    Import-DscResource -ModuleName 'xComputerManagement'
    Import-DscResource -ModuleName 'xPendingReboot'
    Import-DscResource -ModuleName 'xActiveDirectory'
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'

    Node localhost {
        xComputer SetName { 
             Name = 'DC01' 
        }
        xPendingReboot AfterCompRename {
            Name       = 'AfterCompRename'
            DependsOn  = '[xComputer]SetName'
        }
        WindowsFeature ADDSInstall {
            DependsOn = '[xComputer]SetName'
            Ensure = 'Present'
            Name   = 'AD-Domain-Services'
            IncludeAllSubFeature = $true
        }
        WindowsFeature RSATADDSInstall {
            DependsOn = '[xComputer]SetName'
            Ensure = 'Present'
            Name   = 'RSAT-ADDS'
            IncludeAllSubFeature = $true
        }
        xADDomain FirstDomain {
            DependsOn                     = '[WindowsFeature]ADDSInstall'
            DomainName                    = $domainname
            DomainNetbiosName             = $DomainNetbiosName
            DomainAdministratorCredential = $DomainAdminCred
            SafemodeAdministratorPassword = $SafeModeAdminCred
        }
        xPendingReboot AfterDCPromotion {
            Name       = 'AfterDCPromotion'
            DependsOn  = '[xADDomain]FirstDomain'
        }
        LocalConfigurationManager {

            CertificateId = $certthumbprint
            RebootNodeIfNeeded = $true
        }


    }
    

}



#CreateNewADDOmain -ConfigurationData $cd
