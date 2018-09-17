#!/usr/bin/env bash

if [ $UID -ne 0 ]; then
    echo "Run this script as root user please..."
    exit 99
fi

HOME=/home/mandy
USER=mandy

if [ $HOME != '/home/mandy' ]; then
    echo "\$HOME is not '/home/mandy' ($HOME)"
    exit 100
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set +e
source "$DIR/../../.functions"
title "Install"
set -e

# tab width
tabs 4
clear

# Title of script set
TITLE="Fedora Post-Install Script"

# Main
function main {
	echo_message header "Starting 'main' function"
	# Draw window
	MAIN=$(eval `resize` && whiptail \
		--notags \
		--title "$TITLE" \
		--menu "\nWhat would you like to do?" \
		--cancel-button "Quit" \
		$LINES $COLUMNS $(( $LINES - 12 )) \
		'system_update'			'Perform system update' \
		'all'		            'Install all packages' \
		'multimedia'		    'Install multimedia packages' \
		'virtualization'        'Install virtualization packages' \
		'wine'                  'Install wine packages' \
		'developer_tools'       'Install developer tools packages' \
		'development'           'Install development packages' \
		3>&1 1>&2 2>&3)
	# check exit status
	if [ $? = 0 ]; then
		echo_message header "Starting '$MAIN' function"
		$MAIN
	else
	    exit 0
	fi
}


# Fancy colorful echo messages
function echo_message(){
	local color=$1;
	local message=$2;
	if ! [[ $color =~ '^[0-9]$' ]] ; then
		case $(echo -e $color | tr '[:upper:]' '[:lower:]') in
			# black
			header) color=0 ;;
			# red
			error) color=1 ;;
			# green
			success) color=2 ;;
			# yellow
			welcome) color=3 ;;
			# blue
			title) color=4 ;;
			# purple
			info) color=5 ;;
			# cyan
			question) color=6 ;;
			# orange
			warning) color=202 ;;
			# white
			*) color=7 ;;
		esac
	fi
	tput bold;
	tput setaf $color;
	echo '-- '$message;
	tput sgr0;
}


function base {
    add_repositories

    setup_custom_services
set -e
    cat <<'EOL' | sed '/^#/ d' | sed 's/#.*$//g' |  sed '/^$/d'  | tr '\n' ' ' | xargs -I {} sh -c 'dnf install -y {}'
@core
@standard
@hardware-support
@base-x
@firefox
google-chrome-stable
chromium
@fonts
terminus-fonts-console
# fontconfig-enhanced-defaults
# fontconfig-font-replacements
@xfce
plank
paper-icon-theme
@multimedia
@printing
@development-tools
byzanz # record gif
vim

dnf-plugins-core
redhat-rpm-config
dnf-plugin-system-upgrade
rpmconf

htop
iotop

mate-calc
git
tig
gitflow

strace
system-config-printer

i3
i3lock
wmctrl
xterm
zsh
google-roboto-fonts
redshift

unzip
unrar

openssh
arandr
lxappearance
parcellite
byobu
tmux
network-manager-applet
feh
xsel
xclip
variety
paper-icon-theme
yad
thunar
tumbler
unrar
xarchiver
git
tig
ruby
ruby-devel


synergy
pulseaudio

gnome-disk-utility

pluma
gedit
lightdm
xfce4-panel
tint2
xfce4-power-manager
virt-what

jq
ImageMagick

numix-gtk-theme
arc-theme
dmz-cursor-themes

ristretto
gnupg
openssl-devel
gcc-c++
make
neofetch
xfce4-terminal

pasystray
glibc-locale-source

wget
vpnc

dnfdragora
seahorse
gnome-keyring
curl
sqlite

openssh-askpass
shutter
hunspell-en
hunspell-nl

gnome-python2-gconf
qdirstat
font-manager
libXt-devel
libXfixes-devel
libXi-devel


keepassxc
qt5ct
qt-config
qt5-qtstyleplugins
exa
compton
java-1.8.0-openjdk

imwheel

fuse
cifs-utils
gvfs-fuse
fuse-exfat
fuse-sshfs
exfat-utils

atril
rofi

vlc

gnuplot

system-config-kickstart
mediawriter
xss-lock
libvirt
sysstat
albert

openvpn
pykickstart

sublime-text
xbacklight
mesa-dri-drivers

console-setup
xfce4-terminal
xfce4-panel
xfce4-whiskermenu-plugin

lshw
redshift-gtk
xscreensaver
xscreensaver-extras
xscreensaver-gl-extras
qalculate-gtk
parallel
snapd
vokoscreen
perl-File-MimeInfo
EOL
    status=$?
    if [ $status -ne 0 ]; then
        echo "Install exited with status ${status}"
        exit 2
    fi
    echo "will cite" | parallel --citation
    dnf remove gnome-calculator evince file-roller gedit gedit-plugins gnucash ark @kde 'plasma*' xfdesktop -y

    su mandy bash -c "rm -rf ~/.gemrc; ln -sf ${DIR}/../../.gemrc ~/.gemrc"

    gem install json --no-ri --no-rdoc
    gem install teamocil --no-ri --no-rdoc

    # Fixes for pulseaudio
    sed -E -i 's#.*autospawn.*#autospawn = yes#g' /etc/pulse/client.conf
    pulseaudio -k || true

    # install xrectsel
    which xrectsel >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        dnf install autoconf automake -y
        bash ~/dotfiles/installers/install-xrectsel.sh
    fi


    usermod -a -G docker mandy || true
    groupadd power || true
    usermod -a -G power mandy || true
    usermod -a -G disk mandy || true
    chsh -s /bin/zsh mandy || true


    dnf install -y $DIR/rpms/jetbrains-toolbox*.rpm

    set +e
    which xbanish >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        bash $HOME/dotfiles/installers/xbanish.sh
    fi
    set -e

    dnf install https://s3.amazonaws.com/purevpn-dialer-assets/linux/app/purevpn-1.0.0-1.amd64.rpm

    systemctl start firewalld
    virt-what | grep -q -i virtualbox && dnf install -y VirtualBox-guest-additions

    dnf install -y https://download.teamviewer.com/download/linux/teamviewer.x86_64.rpm
    dnf install -y http://download.nomachine.com/download/6.1/Linux/nomachine_6.1.6_9_x86_64.rpm
    dnf install -y http://ftp.gwdg.de/pub/opensuse/distribution/leap/15.0/repo/oss/x86_64/dunst-1.3.2-lp150.1.1.x86_64.rpm
    dnf install $(curl -s https://api.github.com/repos/saenzramiro/rambox/releases/latest | jq -r ".assets[] | select(.name) | select(.browser_download_url | test(\"64.*rpm$\")) | .browser_download_url") -y
    dnf install $( curl -s https://api.github.com/repos/mbusb/multibootusb/releases/latest | jq -r ".assets[] | select(.name) | select(.browser_download_url | test(\".*rpm$\")) | .browser_download_url" | head -1 ) -y


    mkdir -p $HOME/.config/mpd
    touch $HOME/.config/mpd/database
    # Create swap file
    # create_swap_file 4 /swapfile

    su mandy bash -c '
    if [ ! -d "$HOME/.nvm" ]; then
        unset NVM_DIR
        curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm

        nvm install stable
    fi'
    sudo -A chown -R mandy:"$(id -gn mandy)" /home/mandy/.config

    wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/install.sh | sh

    set +x
}


function sys_config {
    localedef -i nl_BE -f UTF-8 nl_BE.UTF-8
    cat <<'EOL' > /etc/locale.conf
LANG=en_US.UTF-8
LANGUAGE="en_US.UTF-8"
LC_CTYPE="en_US.UTF-8"
LC_NUMERIC="nl_BE.UTF-8"
LC_TIME="nl_BE.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_MONETARY="nl_BE.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="nl_BE.UTF-8"
LC_NAME="nl_BE.UTF-8"
LC_ADDRESS="nl_BE.UTF-8"
LC_TELEPHONE="nl_BE.UTF-8"
LC_MEASUREMENT="nl_BE.UTF-8"
LC_IDENTIFICATION="nl_BE.UTF-8"

EOL

#     cat <<'EOL' | tee /etc/fonts/local.conf
#<?xml version='1.0'?>
#<!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
#<fontconfig>
#    <match target="font">
#        <edit name="antialias" mode="assign">
#         <bool>true</bool>
#        </edit>
#        <edit name="autohint" mode="assign">
#         <bool>false</bool>
#        </edit>
#        <edit name="hinting" mode="assign">
#         <bool>true</bool>
#        </edit>
#        <edit name="hintstyle" mode="assign">
#         <const>hintslight</const>
#        </edit>
#        <edit name="lcdfilter" mode="assign">
#         <const>lcddefault</const>
#        </edit>
#        <edit name="rgba" mode="assign">
#         <const>rgb</const>
#        </edit>
#        <edit name="embeddedbitmap" mode="assign">
#         <bool>false</bool>
#        </edit>
#    </match>
#</fontconfig>
#EOL


  cat <<'EOL' > /etc/default/console-setup
# CONFIGURATION FILE FOR SETUPCON

# Consult the console-setup(5) manual page.

ACTIVE_CONSOLES=guess

CHARMAP=guess

CODESET=guess
FONTFACE=TerminusBold
FONTSIZE=16

VIDEOMODE=

# The following is an example how to use a braille font
# FONT='lat9w-08.psf.gz brl-8x8.psf'
EOL

    cat <<'EOL' > /etc/sysctl.conf
# sysctl settings are defined through files in
# /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
#
# Vendors settings live in /usr/lib/sysctl.d/.
# To override a whole file, create a new file with the same in
# /etc/sysctl.d/ and put new settings there. To override
# only specific settings, add a file with a lexically later
# name in /etc/sysctl.d/ and put new settings there.
#
# For more information, see sysctl.conf(5) and sysctl.d(5).

# For IntelliJ products for example
# See https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
fs.inotify.max_user_watches = 524288
net.ipv4.ip_forward=1
# https://superuser.com/questions/351387/how-to-stop-kernel-messages-from-flooding-my-console default 4417
kernel.printk = 2 4 1 7
EOL

# @todo https://coderwall.com/p/66kbaw/adding-entries-to-resolv-conf-on-fedora
    cat <<'EOL' > /etc/resolv.conf
nameserver 1.1.1.1
nameserver 1.0.0.1
EOL


    cat <<'EOL' > /etc/vconsole.conf
KEYMAP="us"
FONT="ter-v32n"
EOL
}


function setup_custom_services {
    cp $DIR/../../services/tty-switching.service /etc/systemd/system/
    systemctl daemon-reload

    systemctl enable tty-switching
    systemctl restart tty-switching
}


function macbook {
    install-service $DIR/../../services/macbook-keyboard.service
    install-service $DIR/../../services/wifi-resume.service
    install-service $DIR/../../services/mount-resume.service

    cat <<'EOL' > /etc/default/console-setup
# CONFIGURATION FILE FOR SETUPCON

# Consult the console-setup(5) manual page.

ACTIVE_CONSOLES=guess

CHARMAP=guess

CODESET=guess
FONTFACE=TerminusBold
FONTSIZE=16x32

VIDEOMODE=

# The following is an example how to use a braille font
# FONT='lat9w-08.psf.gz brl-8x8.psf'
EOL

# Only for Macbook with HiDpi display
# Change font size to 16x32 in /etc/default/console-setup
# Fix alt arrow behaviour of switching ttys: sudo sh -c 'dumpkeys |grep -v cr_Console |loadkeys'
#add-to-file "stty rows 50" "$HOME/.profile"
#add-to-file "stty columns 160" "$HOME/.profile"


}


function setup_firewall {
    set +e
    firewall-cmd --zone=public --permanent --add-service=ssh
    firewall-cmd --zone=public --permanent --add-service=http
    firewall-cmd --zone=public --permanent --add-service=https
    firewall-cmd --zone=public --permanent --add-service=mysql

    firewall-cmd --permanent --new-service=xdebug
    firewall-cmd --zone=public --permanent --add-service=xdebug

    firewall-cmd --permanent --service=xdebug --add-port=9000/tcp
    firewall-cmd --permanent --service=xdebug --add-port=9000/udp

    # KDE Connect
    firewall-cmd --zone=public --permanent --add-port=1714-1764/tcp
    firewall-cmd --zone=public --permanent --add-port=1714-1764/udp


    # Virtualbox webservice
    firewall-cmd --permanent --new-service=vboxweb
    firewall-cmd --zone=public --permanent --add-service=vboxweb
    firewall-cmd --zone=public --permanent --add-port=18083-18083/tcp
    firewall-cmd --zone=public --permanent --add-port=18083-18083/udp


    firewall-cmd --reload
    set -e
}

function add_repositories {
    set -x
    # Persist extra repos and import keys.
    cat << EOF > /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
EOF

    rpm --import https://dl-ssl.google.com/linux/linux_signing_key.pub

    rpm -ivh http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-28.noarch.rpm
    rpm -ivh http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-28.noarch.rpm
    rpm -ivh https://rpms.remirepo.net/fedora/remi-release-28.rpm

    dnf install -y http://mirror.yandex.ru/fedora/russianfedora/russianfedora/free/fedora/releases/28/Everything/x86_64/os/russianfedora-free-release-28-1.noarch.rpm
    # http://mscorefonts2.sourceforge.net/
    rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

    dnf copr enable yaroslav/i3desktop -y
    rpm --import https://dl.tvcdn.de/download/linux/signature/TeamViewer2017.asc

    # For albert
    rpm --import https://build.opensuse.org/projects/home:manuelschneid3r/public_key
    dnf config-manager --add-repo https://download.opensuse.org/repositories/home:manuelschneid3r/Fedora_28/home:manuelschneid3r.repo

    # Sublime text
    rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
    dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo

    set +x
}

function system_update {
    package-cleanup -y --oldkernels --count=5
    dnf update -y --refresh
}



function all {
    base
    multimedia
    virtualization
#    wine
    openbox
#    cinnamon
    networkutilities
    development
    system_update
}

function multimedia {
    # Audio
    dnf install -y ffmpeg flacon shntool cuetools
    dnf install -y mpc mpd mpv rhythmbox ncmpcpp
    dnf install -y $DIR/rpms/cli-visualizer*.rpm
    dnf install -y quodlibet soundconverter

    # Photo
    dnf install -y pinta darktable
    dnf remove -y gimp

    # Video
    dnf install -y vlc

    dnf install -y @multimedia
}

function virtualization {
    set +e
    dnf install -y VirtualBox VirtualBox-webservice
    virtualbox_version=$(vboxmanage --version | grep -Eo '[0-9+]\.[0-9]+\.[0-9]+')
    cd /tmp
    curl -J -O -L https://download.virtualbox.org/virtualbox/${virtualbox_version}/Oracle_VM_VirtualBox_Extension_Pack-${virtualbox_version}.vbox-extpack
    yes | vboxmanage extpack install /tmp/Oracle_VM_VirtualBox_Extension_Pack-${virtualbox_version}.vbox-extpack --accept-license=56be48f923303c8cababb0bb4c478284b688ed23f16d775d729b89a2e8e5f9eb

    VBoxManage setextradata global GUI/Input/HostKeyCombination 65514 # right alt

    dnf install -y virt-manager qemu

    mkdir -p  /etc/systemd/system/vboxweb.service.d
cat <<'EOL' | tee  /etc/systemd/system/vboxweb.service.d/override.conf
[Unit]
Description=VirtualBox Web Service
After=network.target

[Service]
Type=forking
ExecStart=
ExecStart=/usr/bin/vboxwebsrv --pidfile /home/mandy/.vboxweb.pid  --background --host=0.0.0.0
ExecStopPost=
ExecStopPost=/usr/bin/rm /home/mandy/.vboxweb.pid
PIDFile=/home/mandy/.vboxweb.pid
User=mandy
Group=vboxusers

[Install]
WantedBy=multi-user.target
EOL

    systemctl daemon-reload
    systemctl restart vboxweb
    set -e

#    docker run --name vbox_http --restart=always \
#    -p 8888:80 \
#    -e ID_PORT_18083_TCP=IP:18083 \
#    -e ID_NAME="Machine name" \
#    -e ID_USER=username \
#    -e ID_PW='password' \
#    -e CONF_browserRestrictFolders="/data,/home" \
#    -d jazzdd/phpvirtualbox
}

function wine {
    dnf install -y wine playonlinux
}


function openbox {
    dnf install -y openbox openbox-theme-mistral-thin openbox-theme-mistral-thin-dark obconf obmenu
}

function gnome {
    dnf install -y gnome-desktop
}

function cinnamon {
    dnf install -y cinnamon-desktop
}

function networkutilities {
    dnf install -y nmap tcpdump ncdu

}

function development {
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    dnf install -y docker-ce docker-compose
    systemctl enable docker

    dnf install -y meld filezilla ShellCheck
    
    /usr/local/bin/pip install --upgrade mycli
    /usr/local/bin/pip install --upgrade httpie
    
    # The fuck
    dnf install -y python3-devel
    /usr/local/bin/pip install --upgrade thefuck

    # Vagrant
    dnf install -y https://releases.hashicorp.com/vagrant/2.1.2/vagrant_2.1.2_x86_64.rpm

        
    # Install Dry, 
    # dry is a terminal application to manage and monitor Docker containers.
    # See https://moncho.github.io/dry/
    if [ ! -f /usr/local/bin/dry ]; then
        curl -sSf https://moncho.github.io/dry/dryup.sh | sh
        chmod 755 /usr/local/bin/dry
        chmod +x /usr/local/bin/dry
    fi


    dnf install -y https://github.com/browsh-org/browsh/releases/download/v1.4.12/browsh_1.4.12_linux_amd64.rpm

    php_tools

    mkdir -p $HOME/go
}

function php_tools {
    # PHP
    dnf install -y composer php-pecl-imagick kcachegrind
    su mandy bash -c 'composer global require "acacha/llum"'
    su mandy bash -c 'composer global require "acacha/adminlte-laravel-installer"'
    su mandy bash -c 'composer global require "symfony/console"'
    su mandy bash -c 'composer global require "jolicode/jolinotif"'
    su mandy bash -c 'composer global require "squizlabs/php_codesniffer"'
    
    dnf install -y php-pear php-devel re2c
    pecl channel-update pecl.php.net
#    pecl install "channel://pecl.php.net/ui-2.0.0"

}

function developer_tools {
    dnf install -y fedora-packager @development-tools rpmlint
    usermod -a -G mock $USER

    rpmdev-setuptree
}


function idea_configs() {
    su mandy bash -c "find ~ -maxdepth 1 -type d -name '.PhpStorm*' | xargs -I {} mkdir -p '{}/config/colors'"
    su mandy bash -c "find ~ -maxdepth 1 -type d -name '.PhpStorm*' | xargs -I {} cp $DIR/../../.config/.PhpStorm/config/colors/Xresources.icls '{}/config/colors'"

}

# Welcome message
echo_message welcome "$TITLE"

if [ "$1" != '' ]; then
    echo_message header "Starting '$1' function from cli parameter"
    $1
    exit 0
fi
# main
while :
do
	main
done