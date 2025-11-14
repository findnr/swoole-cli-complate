#!/bin/bash
###
 # @Description: auto install samba and config samba
### 

apt install samba samba-common

expect -c "
    spawn smbpasswd -a runner
    expect {
        \"password\" { send \"123456\r\";}
    }
    expect {
        \"password\" { send \"123456\r\";}
    }
expect eof"

sed -i '$a [runner]' /etc/samba/smb.conf
sed -i '$a comment = runner share folder' /etc/samba/smb.conf
sed -i '$a browseable = yes' /etc/samba/smb.conf
sed -i '$a path = /home/runner' /etc/samba/smb.conf
sed -i '$a create mask = 0777' /etc/samba/smb.conf
sed -i '$a directory mask = 0777' /etc/samba/smb.conf
sed -i '$a valid users = runner' /etc/samba/smb.conf
sed -i '$a force user = runner' /etc/samba/smb.conf
sed -i '$a force group = runner' /etc/samba/smb.conf
sed -i '$a public = yes' /etc/samba/smb.conf
sed -i '$a available = yes' /etc/samba/smb.conf
sed -i '$a writable = yes' /etc/samba/smb.conf

sed -i '$a [mnt]' /etc/samba/smb.conf
sed -i '$a comment = runner share folder' /etc/samba/smb.conf
sed -i '$a browseable = yes' /etc/samba/smb.conf
sed -i '$a path = /mnt' /etc/samba/smb.conf
sed -i '$a create mask = 0777' /etc/samba/smb.conf
sed -i '$a directory mask = 0777' /etc/samba/smb.conf
sed -i '$a valid users = runner' /etc/samba/smb.conf
sed -i '$a force user = runner' /etc/samba/smb.conf
sed -i '$a force group = runner' /etc/samba/smb.conf
sed -i '$a public = yes' /etc/samba/smb.conf
sed -i '$a available = yes' /etc/samba/smb.conf
sed -i '$a writable = yes' /etc/samba/smb.conf

chmod 777 /mnt

systemctl restart smbd
