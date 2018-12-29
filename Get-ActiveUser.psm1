function Get-ActiveUser
{
    <#
    .SYNOPSIS
		Retrive list of active users on windows machine
	
	.DESCRIPTION
		Uses WMI, CIM or Query.exe

        This module was created with a powershell.org blogpost in mind
        http://powershell.org/wp/2015/08/28/list-users-logged-on-to-your-machines/
        Created by Jonas Sommer Nielsen
	
	.PARAMETER ComputerName / CN / IP / Hostname
		Optional: Specifies a remote computer to target
	
	.PARAMETER Method
		Optional: Specifies the method to retrieve logged on users. Query, CIM, WMI
	
	.PARAMETER Credential
		Optional: Specifies alternative credentials to use for the WMI connection
	
	.EXAMPLE
        Get-ActiveUser
        Retrieves all users currently logged into the local machine
    
    .EXAMPLE
        Get-ActiveUser -ComputerName TestComputer -Method CIM
        Retrieves all users currently logged into the remote machine "TestComputer" using CIM

    .EXAMPLE
        Get-ActiveUser -ComputerName TestComputer -Method WMI -Credential (Get-Credential)
        Retrieves all users currently logged into the remote machine "TestComputer" using WMI.
        This will prompt for credentials to authenticate the connection.

    .ExternalHelp 
        https://github.com/mrhvid/Get-ActiveUser
        
	.NOTES
        Author: Jonas Sommer Nielsen
        Revised: Ian Mott
    #> 

    [CmdletBinding(DefaultParameterSetName='Standard Parameters', 
                SupportsShouldProcess=$false, 
                PositionalBinding=$false,
                HelpUri = 'https://github.com/mrhvid/Get-ActiveUser',
                ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([string[]])]
    Param
    (
        # Computer name, IP, Hostname
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Default set to localhost",
                   Position=0)]
        [Alias("CN","IP","Hostname")]
        [String]
        $ComputerName = $ENV:COMPUTERNAME,

        # Choose method, WMI, CIM or Query
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Default set to WMI",
            Position=1)]
        [ValidateSet('WMI','CIM','Query')]
        [String]
        $Method = "WMI",

        # Specify Credentials for the remote WMI/CIM queries
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="This is only required for WMI connections. Try the Query or CIM method?",
            Position=2)]
        [pscredential]
        $Credential
    )

    Begin
    {
        Write-Verbose -Message "VERBOSE: Starting Begin"

        $Params = @{}

        if ($ComputerName -notin ($ENV:COMPUTERNAME,"localhost", "127.0.0.1")) {
            if ($Method -in ("WMI","CIM")) {
                $Params.Add("ComputerName",$ComputerName)
                
                if ($Credential -and $Method -eq "WMI") {
                    $Params.Add("Credential",$Credential)
                }
            }

            if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
                Write-Verbose -Message "VERBOSE: Confirmed $ComputerName is reachable by ping"

                if (Test-WSMan @Params -ErrorAction SilentlyContinue -ErrorVariable error_WSMan) {
                    Write-Verbose -Message "VERBOSE: Successfully connected with WSMan"
                } else {
                    Write-Error -Message "ERROR: Failed to connect with WSMan. ErrorMessage: $error_WSMan" -RecommendedAction Stop
                }
                
            } else {
                Write-Error -Message "ERROR: Could not reach $ComputerName by ping. Confirm the computer is reachable." -RecommendedAction Stop
            }
            
        } else {
            Write-Verbose -Message "VERBOSE: ComputerName not set to a remote machine. No need to check for connectivity."
        }
    
        Write-Verbose -Message "VERBOSE: Ending Begin"
    }
    Process
    {
        Write-Verbose -Message "VERBOSE: Starting Process"

        Write-Verbose "$Method selected as method"

        switch ($Method)
        {
            'WMI' 
            {
                Write-Verbose "Contacting $ComputerName via WMI"
        
                $WMI = (Get-WmiObject Win32_LoggedOnUser @Params).Antecedent

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
                $ActiveUsers = (Get-CimInstance Win32_LoggedOnUser @Params).antecedent.name | Select-Object -Unique

            }
            'Query' 
            {
                Write-Verbose "Contacting $ComputerName via Query"
                $Template = @'
 USERNAME              SESSIONNAME        ID  STATE   IDLE TIME  LOGON TIME
>{USER*:jonas}                 console             1  Active    1+00:27  24-08-2015 22:22
 {USER*:test}                                      2  Disc      1+00:27  25-08-2015 08:26
>{USER*:mrhvid}                rdp-tcp#2           2  Active          .  9/1/2015 8:54 PM
'@

                $Query = query.exe user /server $ComputerName
                $ActiveUsers = $Query | ConvertFrom-String -TemplateContent $Template | Select-Object -ExpandProperty User
            }

        }

        Write-Verbose -Message "VERBOSE: Ending process"
    }
    End
    {
        Write-Verbose -Message "VERBOSE: Starting End"

        # Create nice output format
        $UsersComputersToOutput = @()
        foreach($User in $ActiveUsers) {
             $UsersComputersToOutput += New-Object psobject -Property @{ComputerName=$ComputerName;UserName=$User}   
        }

        # output data
        $UsersComputersToOutput
        
        Write-Verbose -Message "VERBOSE: Ending End"
    }
}