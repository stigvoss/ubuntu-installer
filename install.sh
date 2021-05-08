#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

WORKDIR=/tmp
cd $WORKDIR

install()
{
    init

    sudo apt update
    sudo apt upgrade -y

    add_typora_repo
    add_microsoft_repo
    add_signal_repo

    install_apt_packages
    remove_apt_packages
    
    install_microsoft_apt_packages

    replace_system_snap_packages
    install_snap_packages

    install_vscode
    install_discord
    install_viber

    install_teamviewer

    install_minecraft

    install_typora_themes

    install_extensions
    configure_extensions

    install_tresorit
    
    install_jetbrains_toolbox

    install_plexamp

    install_dotbash

    if [[ -n $LAPTOP ]]; then
        install_laptop_apt_packages
    fi

    sudo apt autoremove -y

    configure
}

init()
{
    if [ "$EUID" -eq 0 ]; then
        echo "Please run unprivileged."
        exit
    fi

    sudo hwclock --hctosys 

    if [[ -x "$(command -v gnome-shell)" ]]; then
        GDM_VERSION=$(gnome-shell --version)
        GDM_VERSION=${GDM_VERSION:12}
    fi

    CHASSIS_TYPE=$(sudo dmidecode --string chassis-type)

    LAPTOP=
    if [[ $CHASSIS_TYPE =~ "Laptop" ]] || [[ $CHASSIS_TYPE =~ "Notebook" ]]; then
        LAPTOP=$CHASSIS_TYPE
    fi

    . /etc/lsb-release
}

configure()
{
    sudo update-alternatives --set editor /usr/bin/nvim
}

add_signal_repo()
{
    if [[ ! -e /etc/apt/sources.list.d/signal-xenial.list ]]; then
        wget -qO - https://updates.signal.org/desktop/apt/keys.asc | sudo apt-key add -
        echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
    fi
}

add_typora_repo()
{
    if [[ $(grep -rhE -c ^deb.+typora /etc/apt/sources.list) == 0 ]]; then
        wget -qO - https://typora.io/linux/public-key.asc | sudo apt-key add -
        sudo add-apt-repository 'deb https://typora.io/linux ./'
    fi
}

add_microsoft_repo()
{
    if [[ $(dpkg -s packages-microsoft-prod &> /dev/null) ]]; then
        wget -q https://packages.microsoft.com/config/ubuntu/${DISTRIB_RELEASE}/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
        sudo dpkg -i packages-microsoft-prod.deb

        sudo add-apt-repository universe

        sudo apt install -y apt-transport-https
    fi
}

replace_system_snap_packages()
{
    sudo snap remove gnome-calculator \
        gnome-system-monitor \
        gnome-characters
    sudo apt install -y gnome-calculator \
        gnome-system-monitor \
        gnome-characters
}

install_laptop_apt_packages()
{
    sudo apt install -y \
        tlp \
        tlp-rdw \
        tp-smapi-dkms \
        acpi-call \
        dkms
}

install_microsoft_apt_packages()
{
    if [[ $(apt-cache search "^dotnet-sdk-3.1$") ]]; then
        sudo apt install -y dotnet-sdk-3.1
    else
        echo ".NET Core SDK 3.1 cannot be found."
    fi
    
    if [[ $(apt-cache search "^dotnet-sdk-5.0$") ]]; then
        sudo apt install -y dotnet-sdk-5.0
    else
        echo ".NET Core SDK 5.0 cannot be found."
    fi

    if [[ $(apt-cache search "^powershell$") ]]; then
        sudo apt install -y powershell
    else
        echo "PowerShell Core cannot be found."
    fi
}

install_snap_packages()
{
    sudo snap install telegram-desktop
}

install_apt_packages()
{
    sudo apt update

    sudo apt install -y \
        keepassxc \
        libreoffice \
        kolourpaint \
        gnome-tweaks \
        gnome-calendar \
        compizconfig-settings-manager \
        gnome-photos \
        yubikey-personalization-gui \
        typora \
        remmina \
        curl \
        openssh-server \
        git \
        net-tools \
        xclip \
        debconf-utils \
        signal-desktop \
        htop \
        lm-sensors \
        qrencode \
        gnome-weather \
        cryptsetup \
        wireguard-dkms \
	neovim
}

remove_apt_packages()
{
	sudo apt update
	
	sudo apt remove -y dleyna-renderer
}

install_minecraft()
{
    if [[ $(dpkg -s minecraft-launcher &> /dev/null) ]]; then
        wget https://launcher.mojang.com/download/Minecraft.deb
        sudo apt install -y $WORKDIR/Minecraft.deb
    fi
}

install_vscode()
{
    if [[ $(dpkg -s code &> /dev/null) ]]; then
        wget -O vscode.deb https://go.microsoft.com/fwlink/?LinkID=760868
        sudo apt install -y $WORKDIR/vscode.deb
    fi
}

install_discord()
{
    if [[ $(dpkg -s discord &> /dev/null) ]]; then
        wget https://dl.discordapp.net/apps/linux/0.0.14/discord-0.0.14.deb -O discord.deb
        sudo apt install -y $WORKDIR/discord.deb
    fi
}

install_viber()
{
    if [[ $(dpkg -s viber &> /dev/null) ]]; then
        wget https://download.cdn.viber.com/cdn/desktop/Linux/viber.deb
        if [[ $(apt-cache search "^libssl1.0.0$") ]]; then
            sudo apt install -y $WORKDIR/viber.deb
        elif [[ $(apt-cache search "^libssl1.1$") ]]; then
            dpkg-deb -x viber.deb viber
            dpkg-deb --control viber.deb viber/DEBIAN
            sed -i -e 's/libssl1.0.0/libssl1.1/g' viber/DEBIAN/control
            dpkg -b viber viber-with-libssl1.1.deb
            sudo apt install $WORKDIR/viber-with-libssl1.1.deb
        fi
    fi
}

install_teamviewer()
{
    if [[ $(dpkg -s teamviewer &> /dev/null) ]]; then
        wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb -O teamviewer.deb
        sudo apt install -y $WORKDIR/teamviewer.deb
    fi
}

install_tresorit()
{
    if [[ ! -e ~/.local/share/tresorit/tresorit ]]; then
        wget https://installerstorage.blob.core.windows.net/public/install/tresorit_installer.run
        sh $WORKDIR/tresorit_installer.run
    fi
}

install_jetbrains_toolbox()
{
    wget -cO jetbrains-toolbox.tar.gz "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"
    tar -xzf jetbrains-toolbox.tar.gz
    $WORKDIR/jetbrains-toolbox-*/jetbrains-toolbox
}

install_typora_themes()
{
    if [[ ! -e ~/.config/Typora/themes/ ]]; then
        mkdir -p ~/.config/Typora/themes/
    fi

    wget https://github.com/troennes/quartz-theme-typora/archive/master.zip
    unzip -o master.zip

    mv -f $WORKDIR/quartz-theme-typora-master/theme/*  ~/.config/Typora/themes/
}

install_plexamp()
{   
    if [[ ! -e ~/plexamp.AppImage ]]; then
        wget https://plexamp.plex.tv/plexamp.plex.tv/desktop/Plexamp-3.4.4.AppImage
        mv -f Plexamp-3.4.4.AppImage ~/plexamp.AppImage
        chmod +x ~/plexamp.AppImage

        if [[ ! -d ~/.icons/plexamp/ ]]; then
            mkdir -p ~/.icons/plexamp/
        fi
        wget https://plexamp.com/img/plexamp.svg -O ~/.icons/plexamp/plexamp.svg

        cat >> ~/.local/share/applications/Plexamp.desktop << EOL
[Desktop Entry]
Type=Application
Name=Plexamp
GenericName=Plexamp
Comment=A beautiful Plex music player for audiophiles, curators, and hipsters
Exec=~/plexamp.AppImage %U
Icon=~/.icons/plexamp/plexamp.svg
Terminal=false
Categories=Sound;\s;Audio;
MimeType=application/x-iso9660-appimage;
EOL
    fi
}

install_extensions() {
    if [[ -x "$(command -v gnome-shell)" ]]; then
        EXTENSIONS=(
            "caffeine@patapon.info"
            "clock-override@gnomeshell.kryogenix.org"
            "freon@UshakovVasilii_Github.yahoo.com"
            "dash-to-panel@jderose9.github.com"
            "lockkeys@vaina.lt"
            "panel-osd@berend.de.schouwer.gmail.com"
            "sound-output-device-chooser@kgshank.net"
            "tweaks-system-menu@extensions.gnome-shell.fifi.org"
            "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
            "remove-alt-tab-delay@tetrafox.pw"
        )

        for extension_uuid in ${EXTENSIONS[@]}; do
            install_gnome_extension $extension_uuid
            enable_gnome_extension $extension_uuid
        done
    fi    
}

install_gnome_extension()
{
    EXTENSION_UUID=$1

    wget -qO $WORKDIR/$EXTENSION_UUID.zip https://extensions.gnome.org/download-extension/$EXTENSION_UUID.shell-extension.zip?shell_version=$GDM_VERSION

    if [[ -x "$(command -v gnome-extensions)" ]]; then
        gnome-extensions install $WORKDIR/$EXTENSION_UUID.zip
    else
        if [[ ! -e ~/.local/share/gnome-shell/extensions/$EXTENSION_UUID ]]; then
            mkdir -p ~/.local/share/gnome-shell/extensions/$EXTENSION_UUID
            unzip -o $WORKDIR/$EXTENSION_UUID.zip -d ~/.local/share/gnome-shell/extensions/$EXTENSION_UUID
        fi
    fi

    rm $WORKDIR/$EXTENSION_UUID.zip
}

enable_gnome_extension()
{
    EXTENSION_UUID=$1

    if [[ -x "$(command -v gnome-extensions)" ]]; then
        gnome-extensions enable $EXTENSION_UUID
    else
        gnome-shell-extension-tool -e $EXTENSION_UUID
    fi
}

disable_gnome_extensions()
{
    EXTENSION_UUID=$1

    if [[ -x "$(command -v gnome-extensions)" ]]; then
        gnome-extensions disable $EXTENSION_UUID
    else
        gnome-shell-extension-tool -d $EXTENSION_UUID
    fi
}

configure_extensions()
{
    if [[ ! -e $WORKDIR/ubuntu-installer ]]; then
        cd $WORKDIR
        git clone https://github.com/stigvoss/ubuntu-installer.git
    else
        cd $WORKDIR/ubuntu-installer
        git pull
    fi

    dconf load /org/gnome/shell/extensions/dash-to-panel/ < $WORKDIR/ubuntu-installer/configurations/dash-to-panel.conf
    dconf load /org/gnome/shell/extensions/lockkeys/ < $WORKDIR/ubuntu-installer/configurations/lockkeys.conf
    dconf load /org/gnome/shell/extensions/clock_override/ < $WORKDIR/ubuntu-installer/configurations/clock_override.conf
    dconf load /org/gnome/shell/extensions/panel-osd/ < $WORKDIR/ubuntu-installer/configurations/panel-osd.conf
    dconf load /org/gnome/settings-daemon/plugins/media-keys/ < $WORKDIR/ubuntu-installer/configurations/media-keys.conf
    dconf write /org/gnome/shell/favorite-apps "$(cat $WORKDIR/ubuntu-installer/configurations/favorite-apps.conf)"
}

install_dotbash()
{
    git clone https://github.com/stigvoss/dotconfig.git
    mv $WORKDIR/dotconfig ~
    bash ~/dotconfig/install.sh
}

install
