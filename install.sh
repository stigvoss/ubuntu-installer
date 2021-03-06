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

    if [[ ! -e $WORKDIR/ubuntu-installer ]]; then
        cd $WORKDIR
        git clone https://github.com/stigvoss/ubuntu-installer.git
    else
        cd $WORKDIR/ubuntu-installer
        git pull
    fi
}

configure()
{
    sudo update-alternatives --set editor /usr/bin/nvim
    echo "export QT_QPA_PLATFORMTHEME=gtk2" >> ~/.profile
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
        neovim \
        solaar \
	qt5-style-plugins
}

remove_apt_packages()
{
	sudo apt update
	
	sudo apt remove -y dleyna-renderer
}

install_minecraft()
{
    cd $WORKDIR

    if [[ $(dpkg -s minecraft-launcher &> /dev/null) ]]; then
        wget https://launcher.mojang.com/download/Minecraft.deb -O $WORKDIR/Minecraft.deb
        sudo apt install -y $WORKDIR/Minecraft.deb
    fi
}

install_vscode()
{
    cd $WORKDIR

    if [[ $(dpkg -s code &> /dev/null) ]]; then
        wget -O $WORKDIR/vscode.deb https://go.microsoft.com/fwlink/?LinkID=760868
        sudo apt install -y $WORKDIR/vscode.deb
    fi
}

install_discord()
{
    cd $WORKDIR

    if [[ $(dpkg -s discord &> /dev/null) ]]; then
        wget https://dl.discordapp.net/apps/linux/0.0.15/discord-0.0.15.deb -O $WORKDIR/discord.deb
        sudo apt install -y $WORKDIR/discord.deb
    fi
}

install_viber()
{
    cd $WORKDIR

    if [[ $(dpkg -s viber &> /dev/null) ]]; then
        wget https://download.cdn.viber.com/cdn/desktop/Linux/viber.deb -O $WORKDIR/viber.deb
        if [[ $(apt-cache search "^libssl1.0.0$") ]]; then
            sudo apt install -y $WORKDIR/viber.deb
        elif [[ $(apt-cache search "^libssl1.1$") ]]; then
            dpkg-deb -x $WORKDIR/viber.deb viber
            dpkg-deb --control viber.deb viber/DEBIAN
            sed -i -e 's/libssl1.0.0/libssl1.1/g' viber/DEBIAN/control
            dpkg -b viber viber-with-libssl1.1.deb
            sudo apt install $WORKDIR/viber-with-libssl1.1.deb
        fi
    fi
}

install_teamviewer()
{
    cd $WORKDIR

    if [[ $(dpkg -s teamviewer &> /dev/null) ]]; then
        wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb -O teamviewer.deb
        sudo apt install -y $WORKDIR/teamviewer.deb
    fi
}

install_tresorit()
{
    cd $WORKDIR

    if [[ ! -e ~/.local/share/tresorit/tresorit ]]; then
        wget https://installerstorage.blob.core.windows.net/public/install/tresorit_installer.run -O $WORKDIR/tresorit_installer.run
        sh $WORKDIR/tresorit_installer.run
    fi
}

install_jetbrains_toolbox()
{
    cd $WORKDIR

    wget -cO $WORKDIR/jetbrains-toolbox.tar.gz "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"
    tar -xzf $WORKDIR/jetbrains-toolbox.tar.gz
    $WORKDIR/jetbrains-toolbox-*/jetbrains-toolbox
}

install_typora_themes()
{
    cd $WORKDIR

    if [[ ! -e ~/.config/Typora/themes/ ]]; then
        mkdir -p ~/.config/Typora/themes/
    fi

    wget -O $WORKDIR/quartz-theme.zip https://github.com/troennes/quartz-theme-typora/archive/master.zip
    unzip -o $WORKDIR/quartz-theme.zip
    
    if [[ -e ~/.config/Typora/themes/quartz ]]; then
        rm -rf ~/.config/Typora/themes/quartz
    fi

    mv -f $WORKDIR/quartz-theme-typora-master/theme/quartz  ~/.config/Typora/themes/
}

install_plexamp()
{   
    plexamp_version=$(curl -s https://plexamp.plex.tv/plexamp.plex.tv/desktop/latest.yml | head -n 1 | sed "s/version: //g")

    sudo mkdir -p /opt/Plexamp

    sudo wget -x https://plexamp.plex.tv/plexamp.plex.tv/desktop/Plexamp-$plexamp_version.AppImage -O /opt/Plexamp/plexamp.AppImage
    sudo chmod +x /opt/Plexamp/plexamp.AppImage

    if [[ ! -e /opt/Plexamp/plexamp.svg ]]; then
        sudo wget -x https://plexamp.com/img/plexamp.svg -O /opt/Plexamp/plexamp.svg
    fi

    if [[ ! -e ~/.local/share/applications/Plexamp.desktop ]]; then
        cat > ~/.local/share/applications/Plexamp.desktop << EOL
[Desktop Entry]
Type=Application
Name=Plexamp
GenericName=Plexamp
Comment=A beautiful Plex music player for audiophiles, curators, and hipsters
Exec=/opt/Plexamp/plexamp.AppImage %U
Icon=/opt/Plexamp/plexamp.svg
Terminal=false
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
        gnome-extensions install -f $WORKDIR/$EXTENSION_UUID.zip
    else
        if [[ ! -e ~/.local/share/gnome-shell/extensions/$EXTENSION_UUID ]]; then
            mkdir -p ~/.local/share/gnome-shell/extensions/$EXTENSION_UUID
            unzip -o $WORKDIR/$EXTENSION_UUID.zip -d ~/.local/share/gnome-shell/extensions/$EXTENSION_UUID
        fi
    fi

    if [[ -e $WORKDIR/$EXTENSION_UUID.zip ]]; then
        rm $WORKDIR/$EXTENSION_UUID.zip
    fi
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
    dconf load /org/gnome/shell/extensions/dash-to-panel/ < $WORKDIR/ubuntu-installer/configurations/dash-to-panel.conf
    dconf load /org/gnome/shell/extensions/lockkeys/ < $WORKDIR/ubuntu-installer/configurations/lockkeys.conf
    dconf load /org/gnome/shell/extensions/clock_override/ < $WORKDIR/ubuntu-installer/configurations/clock_override.conf
    dconf load /org/gnome/shell/extensions/panel-osd/ < $WORKDIR/ubuntu-installer/configurations/panel-osd.conf
    dconf load /org/gnome/settings-daemon/plugins/media-keys/ < $WORKDIR/ubuntu-installer/configurations/media-keys.conf
    dconf write /org/gnome/shell/favorite-apps "$(cat $WORKDIR/ubuntu-installer/configurations/favorite-apps.conf)"
}

install_dotbash()
{
    if [[ -e ~/dotconfig ]]; then
        cd ~/dotconfig/
        git pull
    else
        cd ~
        git clone https://github.com/stigvoss/dotconfig.git
    fi

    bash ~/dotconfig/install.sh
}

install
