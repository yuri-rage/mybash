#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

# Check if the home directory and linuxtoolbox folder exist, create them if they don't
LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

if [ ! -d "$LINUXTOOLBOXDIR" ]; then
    echo "${YELLOW}Creating linuxtoolbox directory: $LINUXTOOLBOXDIR${RC}"
    mkdir -p "$LINUXTOOLBOXDIR"
    echo "${GREEN}linuxtoolbox directory created: $LINUXTOOLBOXDIR${RC}"
fi

if [ -d "$LINUXTOOLBOXDIR/mybash" ]; then rm -rf "$LINUXTOOLBOXDIR/mybash"; fi

echo "${YELLOW}Cloning mybash repository into: $LINUXTOOLBOXDIR/mybash${RC}"
git clone https://github.com/yuri-rage/mybash "$LINUXTOOLBOXDIR/mybash"
if [ $? -eq 0 ]; then
    echo "${GREEN}Successfully cloned mybash repository${RC}"
else
    echo "${RED}Failed to clone mybash repository${RC}"
    exit 1
fi

# add variables to top level so can easily be accessed by all functions
PACKAGER=""
SUDO_CMD=""
SUGROUP=""
GITPATH=""
IS_WSL=false

cd "$LINUXTOOLBOXDIR/mybash" || exit
git checkout yuri-bash || exit

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

checkEnv() {
    ## Check for requirements.
    REQUIREMENTS='curl groups sudo'
    for req in $REQUIREMENTS; do
        if ! command_exists "$req"; then
            echo "${RED}To run me, you need: $REQUIREMENTS${RC}"
            exit 1
        fi
    done

    ## Check Package Handler
    PACKAGEMANAGER='nala apt dnf yum pacman zypper emerge xbps-install nix-env'
    for pgm in $PACKAGEMANAGER; do
        if command_exists "$pgm"; then
            PACKAGER="$pgm"
            echo "Using $pgm"
            break
        fi
    done

    if [ -z "$PACKAGER" ]; then
        echo "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi

    if command_exists sudo; then
        SUDO_CMD="sudo"
    elif command_exists doas && [ -f "/etc/doas.conf" ]; then
        SUDO_CMD="doas"
    else
        SUDO_CMD="su -c"
    fi

    echo "Using $SUDO_CMD as privilege escalation software"

    ## Check if the current directory is writable.
    GITPATH=$(dirname "$(realpath "$0")")
    if [ ! -w "$GITPATH" ]; then
        echo "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi

    ## Check SuperUser Group

    SUPERUSERGROUP='wheel sudo root'
    for sug in $SUPERUSERGROUP; do
        if groups | grep -q "$sug"; then
            SUGROUP="$sug"
            echo "Super user group $SUGROUP"
            break
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep -q "$SUGROUP"; then
        echo "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi

    ## check if running in WSL
    if grep -qEi "(Microsoft|microsoft|WSL)" /proc/version &> /dev/null; then
        IS_WSL=true
        echo "WSL detected - will install additional dependencies."
    fi
}

installDepend() {
    ## Check for dependencies.
    DEPENDENCIES='bash bash-completion tar bat tree multitail fontconfig fastfetch wget unzip fontconfig trash-cli xdotool'
    
    # install nala if we don't have it
    if [ "$PACKAGER" = "apt" ]; then
        ${SUDO_CMD} ${PACKAGER} update
        if ! command -v nala &> /dev/null; then
            echo "Installing nala frontend for apt"
            ${SUDO_CMD} ${PACKAGER} install -yq nala
            PACKAGER="nala"
        fi
    fi

    if ! command_exists nvim; then
        # Debian packages are notoriously old
        if [[ "$PACKAGER" = "apt" || "$PACKAGER" = "nala" ]]; then
                curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
                chmod u+x nvim.appimage
                ./nvim.appimage --appimage-extract
                ${SUDO_CMD} mv squashfs-root /opt/neovim
                ${SUDO_CMD} ln -s /opt/neovim/AppRun /usr/bin/nvim
        else
            DEPENDENCIES="${DEPENDENCIES} neovim"
        fi
    fi

    # add fastfetch repo
    if [ "$PACKAGER" = "apt" ] || [ "$PACKAGER" = "nala" ]; then
        ${SUDO_CMD} add-apt-repository ppa:zhangsongcui3371/fastfetch
    fi

    echo "${YELLOW}Installing dependencies...${RC}"
    if [ "$PACKAGER" = "pacman" ]; then
        if ! command_exists yay && ! command_exists paru; then
            echo "Installing yay as AUR helper..."
            ${SUDO_CMD} ${PACKAGER} --noconfirm -S base-devel
            cd /opt && ${SUDO_CMD} git clone https://aur.archlinux.org/yay-git.git && ${SUDO_CMD} chown -R "${USER}:${USER}" ./yay-git
            cd yay-git && makepkg --noconfirm -si
        else
            echo "AUR helper already installed"
        fi
        if command_exists yay; then
            AUR_HELPER="yay"
        elif command_exists paru; then
            AUR_HELPER="paru"
        else
            echo "No AUR helper found. Please install yay or paru."
            exit 1
        fi
        ${AUR_HELPER} --noconfirm -S ${DEPENDENCIES}
    elif [ "$PACKAGER" = "nala" ]; then
        ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
    elif [ "$PACKAGER" = "emerge" ]; then
        ${SUDO_CMD} ${PACKAGER} -v app-shells/bash app-shells/bash-completion app-arch/tar app-editors/neovim sys-apps/bat app-text/tree app-text/multitail app-misc/fastfetch
    elif [ "$PACKAGER" = "xbps-install" ]; then
        ${SUDO_CMD} ${PACKAGER} -v ${DEPENDENCIES}
    elif [ "$PACKAGER" = "nix-env" ]; then
        ${SUDO_CMD} ${PACKAGER} -iA nixos.bash nixos.bash-completion nixos.gnutar nixos.neovim nixos.bat nixos.tree nixos.multitail nixos.fastfetch  nixos.pkgs.starship
    elif [ "$PACKAGER" = "dnf" ]; then
        ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
    else
        ${SUDO_CMD} ${PACKAGER} install -yq ${DEPENDENCIES}
    fi

    # Check to see if the selected Nerd Font is installed (Change this to whatever font you would like)
    FONT_NAME="Fira Code Nerd Font"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        echo "Font '$FONT_NAME' is installed."
    else
        echo "Installing '$FONT_NAME'"
        # Change this URL to correspond with the correct font
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
        FONT_DIR="$HOME/.local/share/fonts"
        # check if the file is accessible
        if wget -q --spider "$FONT_URL"; then
            TEMP_DIR=$(mktemp -d)
            wget -q --show-progress $FONT_URL -O "$TEMP_DIR"/"${FONT_NAME}".zip
            unzip "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR"
            mkdir -p "$FONT_DIR"/"$FONT_NAME"
            mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"
            # Update the font cache
            fc-cache -fv
            # delete the files created from this
            rm -rf "${TEMP_DIR}"
            echo "'$FONT_NAME' installed successfully."
        else
            echo "Font '$FONT_NAME' not installed. Font URL is not accessible."
        fi
    fi
}

installStarship() {
    if command_exists starship; then
        echo "Starship already installed"
        return
    fi

    if ! curl -sS https://starship.rs/install.sh | sh; then
        echo "${RED}Something went wrong during starship install!${RC}"
        exit 1
    fi
}

installFzf() {
    if command_exists fzf; then
        echo "Fzf already installed"
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
        if ! $HOME/.fzf/install --all; then
            echo "${RED}Something went wrong during fzf install!${RC}"
            exit 1
        fi
    fi
}

installZoxide() {
    if command_exists zoxide; then
        echo "Zoxide already installed"
        return
    fi

    if ! curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        echo "${RED}Something went wrong during zoxide install!${RC}"
        exit 1
    fi
}

installKitty() {
    if command_exists kitty; then
        echo "Kitty already installed"
        return
    fi

    if ! curl -sS https://sw.kovidgoyal.net/kitty/installer.sh | sh; then
        echo "${RED}Something went wrong during kitty install!${RC}"
        exit 1
    fi
    ln -svf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
    ln -svf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
}

install_additional_dependencies() {
    # removed needless extra neovim installer and added WSL compatibility packages
    if [ "$IS_WSL" = true ] && { [ "$PACKAGER" = "apt" ] || [ "$PACKAGER" = "nala" ]; }; then
        echo "Installing WSL2 Wayland compatibility packages via kisak-mesa"
        ${SUDO_CMD} add-apt-repository ppa:kisak/kisak-mesa
        ${SUDO_CMD} ${PACKAGER} install mesa-utils -y
    fi
}

create_fastfetch_config() {
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    if [ ! -d "$HOME/.config/fastfetch" ]; then
        mkdir -p "$HOME/.config/fastfetch"
    fi
    # Check if the fastfetch config file exists
    if [ -e "$HOME/.config/fastfetch/config.jsonc" ]; then
        rm -f "$HOME/.config/fastfetch/config.jsonc"
    fi
    # I don't want to keep the cloned repo around, so just copy the file
    cp -v "$GITPATH/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
    cp -v "$GITPATH/rage-logo.png" "$HOME/.config/fastfetch/rage-logo.png"
    # ln -svf "$GITPATH/config.jsonc" "$HOME/.config/fastfetch/config.jsonc" || {
    #     echo "${RED}Failed to create symbolic link for fastfetch config${RC}"
    #     exit 1
    # }
}

linkConfig() {
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    ## Check if a bashrc file is already there.
    OLD_BASHRC="$HOME/.bashrc"
    if [ -e "$OLD_BASHRC" ]; then
        echo "${YELLOW}Moving old bash config file to $HOME/.bashrc.bak${RC}"
        if ! mv "$OLD_BASHRC" "$HOME/.bashrc.bak"; then
            echo "${RED}Can't move the old bash config file!${RC}"
            exit 1
        fi
    fi

    OLD_BASH_ALIASES="$HOME/.bash_aliases"
    if [ -e "$OLD_BASH_ALIASES" ]; then
        echo "${YELLOW}Moving old bash alias file to $HOME/.bash_aliases.bak${RC}"
        if ! mv "$OLD_BASH_ALIASES" "$HOME/.bash_aliases.bak"; then
            echo "${RED}Can't move the old bash alias file!${RC}"
            exit 1
        fi
    fi

    OLD_KITTYCONF="$HOME/.config/kitty/kitty.conf"
    if [ -e "$OLD_KITTYCONF" ]; then
        echo "${YELLOW}Moving old kitty config file to $HOME/.config/kitty/kitty.conf.bak${RC}"
        if ! mv "$OLD_KITTYCONF" "$HOME/.config/kitty/kitty.conf.bak"; then
            echo "${RED}Can't move the old kitty config file!${RC}"
            exit 1
        fi
    fi

    OLD_STARSHIP="$HOME/.config/starship.toml"
    if [ -e "$OLD_STARSHIP" ]; then
        echo "${YELLOW}Moving old starship config file to $HOME/.config/starship.toml.bak${RC}"
        if ! mv "$OLD_STARSHIP" "$HOME/.config/starship.toml.bak"; then
            echo "${RED}Can't move the old starship config file!${RC}"
            exit 1
        fi
    fi

    echo "${YELLOW}Linking new bash config file...${RC}"
    # I don't want to keep the cloned repo around, so just copy the files
    cp -v "$GITPATH/.bashrc" "$HOME/.bashrc"
    cp -v "$GITPATH/.bash_aliases" "$HOME/.bash_aliases"
    cp -v "$GITPATH/starship.toml" "$HOME/.config/starship.toml"
    mkdir -p "$HOME/.config/kitty"
    cp -v "$GITPATH/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    # ln -svf "$GITPATH/.bashrc" "$HOME/.bashrc" || {
    #     echo "${RED}Failed to create symbolic link for .bashrc${RC}"
    #     exit 1
    # }
    # ln -svf "$GITPATH/starship.toml" "$HOME/.config/starship.toml" || {
    #     echo "${RED}Failed to create symbolic link for starship.toml${RC}"
    #     exit 1
    # }
}

checkEnv
installDepend
installStarship
installFzf
installZoxide
installKitty
install_additional_dependencies
create_fastfetch_config

if linkConfig; then
    echo "${GREEN}Done!\nrestart your shell to see the changes.${RC}"
    echo "\nThe ~/linuxtoolbox directory can be removed as desired."
else
    echo "${RED}Something went wrong!${RC}"
fi
