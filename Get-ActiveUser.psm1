<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
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
                $WMI = Get-WmiObject -Class Win32_Process -ComputerName $ComputerName -ErrorAction Stop
                $ProcessUsers = $WMI.getowner().user | Select-Object  -Unique
            }
            'CIM' 
            {
                Write-Verbose "Contacting $ComputerName via CIM"
                $CIM = Get-CimInstance -ClassName Win32_Process -ComputerName $ComputerName -ErrorAction Stop

                Foreach($Process in $CIM) {
                                            $Owners += Invoke-CimMethod -InputObject $Process -MethodName GetOwner              
                                          } 
                $ProcessUsers = $Owners | Select-Object -ExpandProperty User -Unique
            }
            'Query' 
            {
                Write-Verbose "Contacting $ComputerName via Query"
                $Template = @'
 USERNAME              SESSIONNAME        ID  STATE   IDLE TIME  LOGON TIME
>{USER*:jonas}                 console             1  Active    1+00:27  24-08-2015 22:22
 {USER*:test}                                      2  Disc      1+00:27  25-08-2015 08:26
'@

                $Query = query.exe user
                $ProcessUsers = $Query | ConvertFrom-String -TemplateContent $Template | Select-Object -ExpandProperty User
            }

        }

        # Create nice output format
        $UsersComputersToOutput = @()
        foreach($User in $ProcessUsers) {
             $UsersComputersToOutput += New-Object psobject -Property @{ComputerName=$ComputerName;UserName=$User}   
        }

        # output data
        $UsersComputersToOutput
    }
    End
    {
    }
}