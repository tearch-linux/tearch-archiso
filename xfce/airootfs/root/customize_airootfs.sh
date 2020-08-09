#!/bin/bash

# User = liveuser
# Password = empty
OSNAME="TeArch"
count=0

function layout() {
    count=$[count+1]
    echo
    echo "##########################################################"
    tput setaf 1;echo $count. " Function " $1 "has been installed";tput sgr0
    echo "##########################################################"
    echo
}

function deleteXfceWallpapers() {
    rm -rf /usr/share/backgrounds/xfce
}

function renameOSFunc() {
    #Name TeArch
    osReleasePath='/usr/lib/os-release'
    rm -rf $osReleasePath
    touch $osReleasePath
    echo 'NAME="'${OSNAME}'"' >> $osReleasePath
    echo 'ID=tearch' >> $osReleasePath
    echo 'PRETTY_NAME="'${OSNAME}'"' >> $osReleasePath
    echo 'ANSI_COLOR="0;34"' >> $osReleasePath
    echo 'HOME_URL="https://tearch.6tel.net"' >> $osReleasePath
    echo 'SUPPORT_URL="https://tearch.6tel.net/forum"' >> $osReleasePath
    echo 'BUG_REPORT_URL="https://tearch.6tel.net/forum"' >> $osReleasePath

    arch=`uname -m`
}

function umaskFunc() {
    set -e -u
    umask 022
}

function localeGenFunc() {
    sed -i 's/^#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
    export LANGUAGE=en_US.UTF-8
    export LANG=en_US.UTF-8
    #export LC_ALL=en_US.UTF-8
    locale-gen
}

function setTimeZoneAndClockFunc() {
    # Timezone
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    # Set clock to UTC
    hwclock --systohc --utc
}

function editOrCreateConfigFilesFunc () {

    # Locale
    echo "LANG=en_US.UTF-8" > /etc/locale.conf

    sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config
    sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
    sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf
}

function configRootUserFunc() {
    usermod -s /usr/bin/bash root
    cp -aT /etc/skel/ /root/
    chmod 750 /root
}

function createLiveUserFunc () {
	# add liveuser
	useradd -m liveuser -u 500 -g users -G "adm,audio,floppy,log,network,rfkill,scanner,storage,optical,power,wheel" -s /bin/bash
	chown -R liveuser:users /home/liveuser
	passwd -d liveuser
	# enable autologin
	groupadd -r autologin
	gpasswd -a liveuser autologin
	groupadd -r nopasswdlogin
	gpasswd -a liveuser nopasswdlogin
	echo "The account liveuser with no password has been created"
}

function autoLoginFunc() {
#=============#
# Custom code #
#=============#
cat>/etc/lightdm/lightdm.conf<< EOL
[LightDM]
run-directory=/run/lightdm
[Seat:*]
session-wrapper=/etc/lightdm/Xsession
autologin-guest=false
autologin-user=liveuser
autologin-user-timeout=0
greeter-session = lightdm-slick-greeter
greeter-show-manual-login=false
greeter-hide-users=true
allow-guest=false
user-session=xfce
[XDMCPServer]
[VNCServer]
EOL
}

function lightdmThemingFunc() {
#=============#
# Custom code #
#=============#
cat>/etc/lightdm/slick-greeter.conf<< EOL
theme-name = ABCD_blue
icon-theme = Tela
background = /usr/share/backgrounds/tearch-wallpapers/tearchwallpaper1.png
EOL
}

function setDefaultsFunc() {
    export _EDITOR=nano
    echo "EDITOR=${_EDITOR}" >> /etc/environment
    echo "EDITOR=${_EDITOR}" >> /etc/profile
}

function fixHavegedFunc(){
    systemctl enable haveged
}

function fixPermissionsFunc() {
    chmod 755 /etc/sudoers.d
    chmod 440 /etc/sudoers.d/g_wheel
    chown 0 /etc/sudoers.d
    chown 0 /etc/sudoers.d/g_wheel
    chown root:root /etc/sudoers.d
    chown root:root /etc/sudoers.d/g_wheel
    chmod 755 /etc
    chmod 750 /etc/polkit-1/rules.d
    chgrp polkitd /etc/polkit-1/rules.d
    #pkexec chown root:root /etc/sudoers /etc/sudoers.d -R
}

function enableServicesFunc() {
	systemctl enable lightdm.service
	systemctl set-default graphical.target
	systemctl enable NetworkManager.service
  systemctl enable org.cups.cupsd.service
  systemctl enable bluetooth.service
  systemctl enable ntpd.service
  #systemctl enable smb.service
  #systemctl enable nmb.service
  #systemctl enable winbind.service
  systemctl enable avahi-daemon.service
  systemctl enable avahi-daemon.socket
  #systemctl enable tlp.service
  #systemctl enable tlp-sleep.service
  #systemctl enable vnstat.service
}

function fixWifiFunc() {
    #https://wiki.archlinux.org/index.php/NetworkManager#Configuring_MAC_Address_Randomization
    su -c 'echo "" >> /etc/NetworkManager/NetworkManager.conf'
    su -c 'echo "[device]" >> /etc/NetworkManager/NetworkManager.conf'
    su -c 'echo "wifi.scan-rand-mac-address=no" >> /etc/NetworkManager/NetworkManager.conf'
}

function fixHibernateFunc() {
    sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
    sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
    sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf
}

function initkeysFunc() {
    pacman-key --init
    pacman-key --populate archlinux
    #pacman-key --keyserver hkps://hkps.pool.sks-keyservers.net:443 -r 74F5DE85A506BF64
    #pacman-key --keyserver hkp://pool.sks-keyservers.net:80 -r 74F5DE85A506BF64
    #sudo pacman-key --refresh-keys
}

function getNewMirrorCleanAndUpgrade() {
    pacman -Sc --noconfirm
    pacman -Syyu --noconfirm
}

deleteXfceWallpapers
layout deleteXfceWallpapers
umaskFunc
layout umaskFunc
localeGenFunc
layout localeGenFunc
setTimeZoneAndClockFunc
layout setTimeZoneAndClockFunc
editOrCreateConfigFilesFunc
layout editOrCreateConfigFilesFunc
configRootUserFunc
layout configRootUserFunc
createLiveUserFunc
layout createLiveUserFunc
autoLoginFunc
layout autoLoginFunc
setDefaultsFunc
lightdmThemingFunc
layout lightdmThemingFunc
layout setDefaultsFunc
fixHavegedFunc
layout fixHavegedFunc
fixPermissionsFunc
layout fixPermissionsFunc
enableServicesFunc
layout enableServicesFunc
fixWifiFunc
layout fixWifiFunc
fixHibernateFunc
layout fixHibernateFunc
initkeysFunc
layout initkeysFunc
getNewMirrorCleanAndUpgrade
layout getNewMirrorCleanAndUpgrade
renameOSFunc


