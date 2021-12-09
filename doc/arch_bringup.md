Reference: https://wiki.archlinux.org/index.php/Installation_guide

## Initial checkup
Verify the boot mode
If UEFI mode is enabled on an UEFI motherboard, Archiso will boot Arch Linux accordingly via systemd-boot. To verify this, list the efivars directory:
`# ls /sys/firmware/efi/efivars`

### Configure wireless network
Identify network interface via:
`# ip link`

Enable interface:
`# ip link set wlp4s0 up`

Connect to access point via wpa_supplicant:
`# wpa_supplicant -i wlp4s0 -c <(wpa_passphrase "your_SSID" "your_key") &`

Get ip address via DHCP:
`# dhcpcd`

ping internet
`# ping www.google.com`

Update the system clock
`# timedatectl set-ntp true`

## Setup partitions
LVM on LUKS
https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system
section: Encrypted boot partition (GRUB)

```
+---------------+----------------+----------------+----------------+----------------+
|ESP partition: |Boot partition: |Volume 1:       |Volume 2:       |Volume 3:       |
|               |                |                |                |                |
|/boot/efi      |/boot           |root            |swap            |home            |
|               |                |                |                |                |
|               |                |/dev/store/root |/dev/store/swap |/dev/store/home |
|/dev/sdaX      |/dev/sdaY       +----------------+----------------+----------------+
|unencrypted    |LUKS encrypted  |/dev/sdaZ encrypted using LVM on LUKS             |
+---------------+----------------+--------------------------------------------------+

Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048         1050623   512.0 MiB   EF00  EFI System
   2         1050624         1460223   200.0 MiB   8300  Linux filesystem
   3         1460224        41943006   xxx.0 GiB   8E00  Linux LVM (xxx approximate size of drive)
```

`# fdisk /dev/nvme0n1`

### Create 3 partition according the 3 listed

#### Preparing the disk

`# cryptsetup luksFormat /dev/nvme0n1p3`

`# cryptsetup open /dev/nvme0n1p3 lvm`

#### Preparing the logical volumes

`# pvcreate /dev/mapper/lvm`

`# vgcreate CarbonVol /dev/mapper/lvm`

`# lvcreate -L 20G CarbonVol -n root`

`# lvcreate -L 100G CarbonVol -n home`

`# lvcreate -l 100%FREE CarbonVol -n data`

`# mkfs.ext4 /dev/mapper/CarbonVol-root`

`# mkfs.ext4 /dev/mapper/CarbonVol-home`

`# mkfs.ext4 /dev/mapper/CarbonVol-data`

`# mount /dev/mapper/CarbonVol-root /mnt`

`# mkdir /mnt/home`

`# mount /dev/mapper/CarbonVol-home /mnt/home`

`# mkdir /mnt/data`

`# mount /dev/mapper/CarbonVol-data /mnt/data`

#### Preparing the boot partition

`# cryptsetup luksFormat /dev/nvme0n1p2`

`# cryptsetup open /dev/nvme0n1p2 boot`

`# mkfs.ext2 /dev/mapper/boot`

`# mkdir /mnt/boot`

`# mount /dev/mapper/boot /mnt/boot`

`# mkfs.fat -F32 /dev/nvme0n1p1`

`# mkdir /mnt/boot/efi`

`# mount /dev/nvme0n1p1 /mnt/boot/efi`

#### Perform the actual archlinux install

`# pacstrap /mnt base`

#### Generate fstab

`# genfstab -U /mnt >> /mnt/etc/fstab`

`# arch-chroot /mnt`

To avoid the double entry for unlocking  /boot, follow the instructions at Dm-crypt/Device encryption#Keyfiles to:

1. Create a randomtext keyfile,

`# dd bs=512 count=4 if=/dev/urandom of=/etc/crypto_keyfile.bin`

2. Setup proper permission

`# chmod 000 /etc/crypto_keyfile.bin`

3. Add the keyfile to the (/dev/nvme0n1p2) boot partition's LUKS header and

`# cryptsetup luksAddKey /dev/nvme0n1p2 /etc/crypto_keyfile.bin`

4. Add the /etc/crypttab line to unlock it automatically at boot.

`# boot /dev/nvme0n1p2	/etc/crypto_keyfile.bin luks`

#### Update region and time

`# ln -sf /usr/share/zoneinfo/Region/City /etc/localtime`

`# hwclock --systohc`

Locale `# locale-gen`

#### Create file: __ /etc/locale.conf __ with:
```
LANG=en_US.UTF-8
```

#### Hostname:
Create file: __ /etc/hostname __ with: _myhostname_

Addd line to __ /etc/hosts __:
```
127.0.1.1	myhostname.localdomain	myhostname
```

#### Install basic tools
`# pacman -S base-devel`

`# pacman -S grub`

`# pacman -S efibootmgr`

`# pacman -S neovim`

`# pacman -S wpa_supplicant dhcpcd dialog`


#### Configuring mkinitcpio
`# vim /etc/mkinitcpio.conf`
```
----------------------------------------------------------------
MODULES="nvme"
HOOKS="... keyboard block encrypt lvm2 ... filesystems ..."
----------------------------------------------------------------
```

#### Configuring the boot loader
`# vim /etc/default/grub`
```
----------------------------------------------------------------
GRUB_CMDLINE_LINUX="... cryptdevice=UUID=6de42073-116c-43a5-82a2-e913d0c111f8:lvm ..."
GRUB_ENABLE_CRYPTODISK=y
----------------------------------------------------------------
( UUID=<of root file system>:</dev/mapper/ volume name> )
```

#### Install new initramfs
`# mkinitcpio -p linux`

`# grub-mkconfig -o /boot/grub/grub.cfg`

`# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --recheck`

#### Adding a user:
`# useradd -m -s /bin/bash hjz`
`# passwd hjz`
`# usermod -aG root hjz`
`# usermod -aG adm hjz`
`# usermod -aG wheel hjz`
`# usermod -aG ftp hjz`
`# usermod -aG uucp hjz`
`# usermod -aG log hjz`
`# usermod -aG rfkill hjz`
`# usermod -aG systemd-journal hjz`

#### Setup sudo
`# pacman -S sudo`
`# visudo    (uncomment WHEEL PASSWORDLESS)`


## REBOOT SYSTEM!!!

#### Verify hjz have sudo permission

#### Disable root login
`# sudo passwd -l root`

#### Setup wifi-profile
`# wifi-menu`
`# netcl enable "wlp4s0-221b_baker_st"`

#### Update packages
`# pacman -Syu`

#### INSTALL X11

`# pacman -S xorg-server xorg-apps`

`# pacman -S i3 rxvt-unicode dmenu`

#### add to ~/.zprofile or ~/.bash_profile
```
if [ -z "$DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec startx
fi
```

copy .xinitrc .xresource

#### INSTALL TOOL TO BOOTSTRAP

`# pacman -S git openssh`

`# ssh-keygen -t rsa -b 4096`

#### FONTS
`# pacman -S ttf-dejavu`


## Misc
- Setup pass
- i3 remove boarder

`# pacman -S vlc qt4`

`# pacman -S adobe-source-han-sans-otc-fonts noto-fonts-emoji`

`# pacman -S pulse pulseaudio-alsa libpulse alsa-plugins alsa-utils`

`# pacman -S htop`

`# pacman -S clang`

`# pacman -S xf86-video-intel xf86-input-libinput vulkan-intel`

`# pacman -S wpa_actiond`

`# systemctl enable/start netctl-auto@wlps4.service`

`# pacman -S powertop tlp tp_smapi acpi_call`

`# systemctl mask systemd-rfkill.service`

`# systemctl mask systemd-rfkill.socket`

`# systemctl enable tlp`

`# systemctl enable tlp-sleep`

- install pacaur

#### Consider install the following pacaur packages
- android-studio
- drive
- mons
- skypeforlinux
- spotify
- xss-lock
- yubico-yubioath-desktop
- pcsclite 
- pcsc-tools
- cower
- pacaur
- siji-git
- polybar
- urxvt-resize-font-git

Enable lock screen
`# sudo systemctl enable screen_lock@hjz`

#### setup yubikey
https://wiki.archlinux.org/index.php/yubikey

Enable Yubikey
`# systemctl start/enable pcscd`
