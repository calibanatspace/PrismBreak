#!/bin/bash

cat > prismbreak-ng2.sh <<'CATEND'
#!/bin/bash

dialog --msgbox "Install Grub\n\nIn the next step, grub will be installed." 15 40
pacman -S --noconfirm sudo grub bash-completion os-prober ntp joe diffutils gettext curl yajl wget
mkdir aur
cd aur
wget https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz
tar -xzvf package-query.tar.gz
cd package-query
makepkg -s --asroot
pacman -U --noconfirm package-query-*.tar.xz
cd ..

wget https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz
tar -xzvf yaourt.tar.gz
cd yaourt
makepkg -s --asroot
pacman -U yaourt-*.tar.xz

yaourt -S --noconfirm --tmp . jdk

# install wildfly

#read
echo
echo Press Return...
echo
read

dialog --msgbox "Configure Grub\n\nIn the next step, Grub will be configured." 15 40
grub-install --target=i386-pc --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
#read

echo
echo Press Return...
echo
read

exit
CATEND

cat > prismbreak-ng3.sh <<'CATEND2'
#!/bin/bash

dialog --msgbox "Configure basesystem\n\nIn the next step, the basesystem will be configured." 15 40

server_locale=$(dialog --stdout --inputbox "Please enter the locale you want to use" 15 40 "de_DE.UTF-8 UTF-8")
echo $server_locale >> /etc/locale.gen
locale-gen
localectl set-locale LANG="$server_locale"

echo
echo Press Return...
echo
read

server_keymap=$(dialog --stdout --inputbox "Please enter the keymap you want to use" 15 40 "de-latin1")
loadkeys $server_keymap
echo KEYMAP=$server_keymap >> /etc/vconsole.conf
#read

echo
echo Press Return...
echo
read

server_hostname=$(dialog --stdout --inputbox "Please enter the hostname you want to use" 15 40 "prismbreak_vm")
hostnamectl set-hostname $server_hostname
#read

echo
echo Press Return...
echo
read

server_timezone=$(dialog --stdout --inputbox "Please enter the timezone you want to use" 15 40 "Europe/Berlin")
timedatectl set-timezone $server_timezone
#read

echo
echo Start ntp
echo
systemctl start ntpd.service
systemctl enable ntpd.service
#read

echo
echo Start dhcpd
echo
read
systemctl start dhcpcd.service
systemctl enable dhcpcd.service
#read

echo
echo Press Return...
echo
read

dialog --msgbox "Reboot into basesystem\n\nBasesystem is installed and configured, will now reboot. You should remove the install medium after reboot." 15 40
rm prismbreak-ng3.sh
reboot
CATEND2

chmod u+x prismbreak-ng2.sh
chmod u+x prismbreak-ng3.sh


# setup a tempfile for filling the returnvalues from dialog with
#tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
#trap "rm -f $tempfile" 0 1 2 5 15

dialog --msgbox "This is the PrismBreakKonfigurator. With it you can setup your own little Server based on ArchLinux. On the following pages you can install and configure some services. \n\nVersion: 0.0.1-20140517" 15 40

## Ask the following infos:
## Server IP address
## Username
## Password
#server_address=$(dialog --stdout --inputbox "Please enter the address of the server, which should be configured." 15 40 "192.168.1.23")

#cat $tempfile
#echo $address

#server_username=$(dialog --stdout --inputbox "Please enter the username, which should be used to connect to the server via ssh" 15 40 "root")
#server_password=$(dialog --stdout --passwordbox "Please enter the password for the username, which should be used to connect to the server via ssh" 15 40 )

#echo $server_address
#echo $server_username
#echo $server_password


dialog --msgbox "Create partition\n\nIn the first step, the partition on the harddisk will be created." 15 40
echo "
p
d
2
n
e
2


n
l


p
w
" | fdisk /dev/sda
sync
partprobe
echo
echo Press Return...
echo
read

# resize partitionen
#resize2fs /dev/sda1
#read

dialog --msgbox "Format partition\n\nIn the next step, the partition on the harddisk will be formated." 15 40
mkfs.ext4 /dev/sda5
echo
echo Press Return...
echo
read
#read

dialog --msgbox "Mount partition\n\nIn the next step, the partition on the harddisk will be mounted." 15 40
mount /dev/sda5 /mnt
echo
echo Press Return...
echo
read
#read

dialog --msgbox "Create swap\n\nIn the next step, the swap file will be created." 15 40
fallocate -l 1GB /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
echo
echo Press Return...
echo
read
#read

dialog --msgbox "Install basesystem\n\nIn the next step, the basesystem will be installed. This could take some time." 15 40
pacstrap /mnt base base-devel dialog
echo
echo Press Return...
echo
read
#read

dialog --msgbox "Create fstab\n\nIn the next step, /etc/fstab will be created." 15 40
genfstab -p /mnt >> /mnt/etc/fstab
echo '/swapfile none swap defaults 0 0
' >> /mnt/etc/fstab
cp prismbreak-ng2.sh /mnt/root
cp prismbreak-ng3.sh /mnt/root

dialog --msgbox "Switch to chroot\n\nIn the next step, system will switch to chroot and install/configure grub." 15 40
arch-chroot /mnt /root/prismbreak-ng2.sh
#read

rm /mnt/root/prismbreak-ng2.sh
echo
echo Press Return...
echo
read

dialog --msgbox "Umount\n\nIn the next step, mounted installfolder will be unmounted." 15 40
umount -R /mnt

# enable sshd
dialog --msgbox "Reboot\n\nIn the next step, system will reboot. After reboot, login into system and start ./prismbreak-ng3.sh." 15 40
reboot
