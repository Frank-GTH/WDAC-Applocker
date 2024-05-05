#Requires -Module Applocker
#Requires -PSEdition Desktop

Function Get-AppLockerPolicyInfo {
<#
.SYNOPSIS
    Display the rule collections info: type, enforcement mode, rules count...

.DESCRIPTION
    Get the exetended info that applies to rule collections

.PARAMETER Effective
    Swtich to get the effective Applocker policy

.PARAMETER Local
    Swtich to get the local Applocker policy

.PARAMETER InputObject
    To be used with the pipeline, see examples

.EXAMPLE
    Get-AppLockerPolicyInfo | ft -AutoSize

    Without parameter, it displays rule collections info from the effective policy

.EXAMPLE
    Get-AppLockerPolicyInfo -Local | Format-Table -AutoSize

    Use the 'local' switch to display rule collections info from the local policy

.EXAMPLE
    Get-AppLockerPolicy -Local | Get-AppLockerPolicyInfo -Verbose | ft -AutoSize

    Use the built-in Get-AppLockerPolicy with its local switch and pipe it to 
    Get-AppLockerPolicyInfo to display rule collections info

.EXAMPLE
    Get-AppLockerPolicy -Ldap "LDAP://$((Get-GPO -Name 'myGPOName').path)" -Domain | 
    Get-AppLockerPolicyInfo | ft -AutoSize

    Use the built-in Get-AppLockerPolicy and Get-GPO cmdlets to read an Applocker policy stored 
    in Active Directory and pipe it to Get-AppLockerPolicyInfo to display rule collections info
#>
[CmdletBinding(DefaultParameterSetName='Effective')]
Param(
[Parameter(ParameterSetName='Effective')]
[Switch]$Effective,

[Parameter(ParameterSetName='Local')]
[switch]$Local,

[Parameter(ParameterSetName='Piped',ValueFromPipeline)]
[Microsoft.Security.ApplicationId.PolicyManagement.PolicyModel.AppLockerPolicy]$InputObject
)
Begin {}
Process {
    try {
        $HT = @{ ErrorAction = 'Stop'}
        Switch ($PSCmdlet.ParameterSetName) {
            Effective {
                $data =  Get-AppLockerPolicy -Effective @HT
                Write-Verbose 'Successfully read effective Applocker policy'
            }
            Local {
                $data =  Get-AppLockerPolicy -Local @HT
                Write-Verbose 'Successfully read local Applocker policy'
            }
            Piped {
                $data = $InputObject
                Write-Verbose 'Successfully read piped Applocker policy'
            }
            default {}
        }
        if ($data) {
            $data.RuleCollections | Select-Object -Property *
        }
    } catch {
        Write-Warning -Message "Failed to get Applocker extended info because $($_.Exception.Message)"
    }
}
End {}
}

Get-AppLockerPolicyInfo | ft -AutoSize

# Native Applocker info - export
Get-AppLockerPolicy -Effective -Xml | Set-Content ('c:\temp\APLcurr.xml')

# Native Applocker info - show
(Get-AppLockerPolicy -Local).RuleCollections | Select * | ft -AutoSize
(Get-AppLockerPolicy -Effective).RuleCollections | Select * | ft -AutoSize