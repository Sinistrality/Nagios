#Prerequistes
#1 Make the powershell script executable via (sudo chmod +x)
#2 Dependencies arping (sudo apt install arping - y)
#3 Dependencies Powershell
#4 Add arping to visudo so it can execute without sudo (sudo visudo -> then add line - nagios ALL=(ALL:ALL) NOPASSWD:/usr/sbin/arping)
#5 Create /home/nagios/snap/powershell directory (and give the account rights to it) so it has a temporary area to execute scripts
#6 Create run directory for nagios user  (cat /etc/passwd | grep nagios -> Take the first number next to nagios and
#put it in this command sudo mkdir /run/user/####/snap.powershell)Ex: sudo mkdir /run/user/1001/snap.powershell

#Add to commands.cfg
#____________________________________________________________________________
##Check For Duplicate MAC Addresses on an IP
#define command {
#    command_name     check_dup_ip
#    command_line     powershell /usr/local/nagios/libexec/DetectDuplicateIPInLinuxARPTable.ps1 -Hostname $HOSTADDRESS$ -Interface "ens33"
#    }
#____________________________________________________________________________
#Define service
#; Check ARP Table For Duplicate IP's
#define service {
#use                     generic-service
#hostgroup               Switches
#service_description     Duplicate IP
#check_interval          60
#check_command           check_dup_ip
#}





    #Parameters - Exit Code Number
    Param(
    [Parameter(Mandatory=$false)] [String[]] $Hostname,
    [Parameter(Mandatory=$false)] [String[]] $Interface
    )

#Set your interface to use default linux one if not specified
If ($null -eq $Hostname){$Hostname = "172.16.7.32"}
If ($null -eq $interface){$interface = "ens33"}

#Turn on console output debug mode#
$DebugModeOn = $false
If ($DebugModeOn -eq $true){
Write-Host "Hostname: $Hostname"
Write-Host "Interface: $Interface"
}
#Sets the function to feed the right error code out
Function ExitCode{
    #Parameters - Exit Code Number
    Param(
    [Parameter(Mandatory=$true)] [int32] $ExitCode,
    [Parameter(Mandatory=$true)] [String[]] $OutputMessage
    )

    #Writes output to console if run standalone
    Write-Output $OutputMessage
    #Writes output to Nagios
    Write-Information $OutputMessage
    Exit $ExitCode
    #[Environment]::Exit($ExitCode)   

#End Function    
}

#Checks to make sure variable is there before proceeding
    #Makes sure there's a hostname to search
If ($null -eq $Hostname){
    If ($DebugModeOn -eq $true){Write-Host "Could not connect to $Hostname" -ForegroundColor Yellow}
    $OutputMessage = "CRITICAL - No -hostname variable specified for the script."
    ExitCode -ExitCode "2" -OutputMessage $OutputMessage
}
#Checks to make sure there's a connection before proceeding
Write-Host "Testing Connection..."
If (Test-Connection -ComputerName $Hostname -Count 1){

#If you can connect proceed to checking status

#Run arping
If ($DebugModeOn -eq $true){Write-Host "Running arping..."}
$MACAddress = & sudo arping -d -I $interface -c 2 $Hostname | egrep -o '([0-9a-f]{2}:){5}[0-9a-f]{2}' | sort --unique

#Check the count of unique MAC Addresses
    If ($MACAddress.count -gt "1")
    {   #Reacts if there are duplicate addresses 
        If ($DebugModeOn -eq $true){Write-Host "Duplicate MAC Addresses Detected $MACAddress"}
        $ExitCode = "1"
        $OutputMessage = "WARNING: Duplicate MAC Addresses Detected $MACAddress"
    }

    If ($MACAddress.count -eq "1")
    {   #Reacts if there's one address 
    If ($DebugModeOn -eq $true){Write-Host "Only one MAC Address Detected"}
        $ExitCode = "0"
        $OutputMessage = "OK - No duplicate addresses detected"
    }

    ExitCode -ExitCode $ExitCode -OutputMessage $OutputMessage
}else{
    #Could not connect
    If ($DebugModeOn -eq $true){Write-Host "Could not connect to $Hostname"}
    $OutputMessage = "Could not connect to $Hostname"
    ExitCode -ExitCode "2" -OutputMessage $OutputMessage
}
