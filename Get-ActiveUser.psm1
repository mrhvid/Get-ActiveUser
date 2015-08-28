<#
.Synopsis
   Retrive list of active users on windows machine
.DESCRIPTION
   Uses WMI, CIM or Query.exe
.EXAMPLE
PS C:\> Get-ActiveUser localhost -Method Query

ComputerName UserName
------------ --------
localhost    jonas
localhost    test

.EXAMPLE
PS C:\> Get-ActiveUser localhost -Method wmi

ComputerName UserName
------------ --------
localhost    Jonas

.EXAMPLE
PS C:\> Start-Multithread -Script {param($C) Get-ActiveUser -ComputerName $C -Method Query} -ComputerName ::1,Localhost | Out-GridView

.NOTES
   This module was created with a powershell.org blogpost in mind
   Created by Jonas Sommer Nielsen

#>
function Get-ActiveUser
{
    [CmdletBinding(DefaultParameterSetName='Standard Parameters', 
                SupportsShouldProcess=$true, 
                PositionalBinding=$false,
                HelpUri = 'https://github.com/mrhvid/Get-ActiveUser',
                ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([string[]])]
    Param
    (
        # Computer name, IP, Hostname
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String]
        $ComputerName,

        # Choose method, WMI, CIM or Query
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=1)]
        [ValidateSet('WMI','CIM','Query')]
        [String]
        $Method
    )

    Begin
    {
    }
    Process
    {
        Write-Verbose "$Method selected as method"

        switch ($Method)
        {
            'WMI' 
            {
                Write-Verbose "Contacting $ComputerName via WMI"
          
                $WMI = (Get-WmiObject Win32_LoggedOnUser).Antecedent
                $ActiveUsers = @()
                foreach($User in $WMI) {
                    $StartOfUsername = $User.LastIndexOf('=') + 2
                    $EndOfUsername = $User.Length - $User.LastIndexOf('=') -3
                    $ActiveUsers += $User.Substring($StartOfUsername,$EndOfUsername)
                }
                $ActiveUsers = $ActiveUsers | Select-Object -Unique

            }
            'CIM' 
            {
                Write-Verbose "Contacting $ComputerName via CIM"
                $ActiveUsers = (Get-CimInstance Win32_LoggedOnUser -ComputerName $ComputerName).antecedent.name | Select-Object -Unique

            }
            'Query' 
            {
                Write-Verbose "Contacting $ComputerName via Query"
                $Template = @'
 USERNAME              SESSIONNAME        ID  STATE   IDLE TIME  LOGON TIME
>{USER*:jonas}                 console             1  Active    1+00:27  24-08-2015 22:22
 {USER*:test}                                      2  Disc      1+00:27  25-08-2015 08:26
'@

                $Query = query.exe user /server $ComputerName
                $ActiveUsers = $Query | ConvertFrom-String -TemplateContent $Template | Select-Object -ExpandProperty User
            }

        }

        # Create nice output format
        $UsersComputersToOutput = @()
        foreach($User in $ActiveUsers) {
             $UsersComputersToOutput += New-Object psobject -Property @{ComputerName=$ComputerName;UserName=$User}   
        }

        # output data
        $UsersComputersToOutput
    }
    End
    {
    }
}