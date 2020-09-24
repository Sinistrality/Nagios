# Nagios Powershell Script
Nagios Scripts

Duplicate IP

> Prerequistes

1. Move the script to the nagios script directory, then make the powershell script executable via (sudo chmod +x)
2. Dependencies arping (sudo apt install arping - y)
3. Dependencies Powershell
4. Add arping to visudo so it can execute without sudo (sudo visudo -> then add line - nagios ALL=(ALL:ALL) NOPASSWD:/usr/sbin/arping)
5. Create /home/nagios/snap/powershell directory (and give the account rights to it) so it has a temporary area to execute scripts
6. Create run directory for nagios user  (cat /etc/passwd | grep nagios -> Take the first number next to nagios and put it in this command sudo mkdir /run/user/####/snap.powershell)Ex: sudo mkdir /run/user/1001/snap.powershell

**Add to commands.cfg**

```
; Check For Duplicate MAC Addresses on an IP

define command {
    command_name     check_dup_ip   
    command_line     powershell /usr/local/nagios/libexec/DetectDuplicateIPInLinuxARPTable.ps1 -Hostname $HOSTADDRESS$ -Interface "ens33"   
    }
```

**Define service**
```
; Check ARP Table For Duplicate IP's
define service {
use                     generic-service
hostgroup               Switches
service_description     Duplicate IP
check_interval          60
check_command           check_dup_ip
}
```
