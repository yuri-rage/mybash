#!/usr/bin/env bash
iatest=$(expr index "$-" i)

#######################################################
# SOURCED ALIASES AND SCRIPTS BY zachbrowne.me
#######################################################
if [ -f /usr/bin/fastfetch ]; then
    if [[ "$TERM" == "xterm-kitty" ]]; then
        fastfetch
    fi
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Enable bash programmable completion features in interactive shells
if [ -f /usr/share/bash-completion/bash_completion ]; then
	. /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi

# use a separate bash alias file
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

#######################################################
# EXPORTS
#######################################################

# Disable the bell
if [[ $iatest -gt 0 ]]; then bind "set bell-style visible"; fi

# Expand the history size
export HISTFILESIZE=10000
export HISTSIZE=500
export HISTTIMEFORMAT="%F %T" # add timestamp to history

# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS
shopt -s checkwinsize

# Causes bash to append to history instead of overwriting it so if you start a new terminal, you have old session history
shopt -s histappend
PROMPT_COMMAND='history -a'

# set up XDG folders
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Seeing as other scripts will use it might as well export it
# export LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

# Allow ctrl-S for history navigation (with ctrl-R)
[[ $- == *i* ]] && stty -ixon

# Ignore case on auto-completion
# Note: bind used instead of sticking these in .inputrc
if [[ $iatest -gt 0 ]]; then bind "set completion-ignore-case on"; fi

# Show auto-completion list automatically, without double tab
if [[ $iatest -gt 0 ]]; then bind "set show-all-if-ambiguous On"; fi

# Set the default editor
export EDITOR=nvim
export VISUAL=nvim

# To have colors for ls and all grep commands such as grep, egrep and zgrep
export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'
#export GREP_OPTIONS='--color=auto' #deprecated

# Check if ripgrep is installed
if command -v rg &> /dev/null; then
    # Alias grep to rg if ripgrep is installed
    alias grep='rg'
else
    # Alias grep to /usr/bin/grep with GREP_OPTIONS if ripgrep is not installed
    alias grep="/usr/bin/grep $GREP_OPTIONS"
fi
unset GREP_OPTIONS

# Color for manpages in less makes manpages a little easier to read
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

#######################################################
# SPECIAL FUNCTIONS
#######################################################

# update unmnaged packages
update-mybash() {
    command_exists() {
        command -v "$1" >/dev/null 2>&1
    }

    local SUDO_CMD
    if command_exists sudo; then
        SUDO_CMD="sudo"
    elif command_exists doas && [ -f "/etc/doas.conf" ]; then
        SUDO_CMD="doas"
    else
        SUDO_CMD="su -c"
    fi

    local SUPERUSERGROUP='wheel sudo root'
    for sug in $SUPERUSERGROUP; do
        if groups | grep -q "$sug"; then
            SUGROUP="$sug"
            echo "Super user group $SUGROUP"
            break
        fi
    done

    ## check for elevated privileges
    if ! groups | grep -q "$SUGROUP"; then
        echo "You need to be a member of the sudo group to run me!"
        exit 1
    fi

    local wd="$PWD"
    local tmp_dir="/tmp/mybash_update_$(date +%Y%m%d_%H%M%S)"
    local nvim_dir="/opt/neovim"
    local nvim_bin="/usr/bin/nvim"
    local nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"

    mkdir -p $tmp_dir

    # update neovim
    local nvim_prev
    local nvim_current

    if [ -d "$nvim_dir" ]; then
        nvim_prev=$(nvim -v | head -n 1 | awk '{print $2}')
        echo "Downloading latest neovim..."
        curl -Lo "$tmp_dir/nvim.appimage" $nvim_url
        chmod u+x "$tmp_dir/nvim.appimage"
        (cd $tmp_dir && ./nvim.appimage --appimage-extract)
        ${SUDO_CMD} mv "$tmp_dir/squashfs-root" $nvim_dir
        ${SUDO_CMD} ln -svf /opt/neovim/AppRun $nvim_bin
        nvim_current=$(nvim -v | head -n 1 | awk '{print $2}')
    fi

    # update starship
    local starship_prev=$(starship --version | head -n 1 | awk '{print $2}')
    echo "Downloading latest starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    local starship_current=$(starship --version | head -n 1 | awk '{print $2}')

    # update fzf
    local fzf_prev=$(fzf --version)
    cd $HOME/.fzf
    git fetch
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]; then
        echo "Pulling latest fzf updates..."
        git pull
        $HOME/.fzf/install --all
    fi

    # update zoxide
    local zoxide_prev=$(zoxide --version | head -n 1 | awk '{print $2}')
    echo "Downloading latest zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    local zoxide_current=$(zoxide --version | head -n 1 | awk '{print $2}')

    # update kitty
    local kitty_prev=$(kitty --version 2>/dev/null | head -n 1 | awk '{print $2}')
    echo "Downloading latest kitty..."
    curl -sS https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    ln -svf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
    ln -svf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
    local kitty_current=$(kitty --version 2>/dev/null | head -n 1 | awk '{print $2}')

    /bin/rm -rf $tmp_dir
    cd $wd
    echo # new line

    if [ "$nvim_current" = "" ]; then
        echo "Neovim not updated     : Use your package manager"
    elif [ "$nvim_prev" != "$nvim_current" ]; then
        echo "Neovim updated         : $nvim_prev -> $nvim_current"
    else
        echo "Neovim is up to date   : $nvim_current"
    fi

    if [ "$starship_prev" != "$starship_current" ]; then
        echo "Starship updated       : $starship_prev -> $starship_current"
    else
        echo "Starship is up to date : $starship_current"
    fi

    local fzf_current=$(fzf --version)
    if [ "$fzf_prev" != "$fzf_current" ]; then
        echo "fzf updated            : $fzf_prev -> $fzf_current"
    else
        echo "fzf is up to date      : $fzf_current"
    fi

    if [ "$zoxide_prev" != "$zoxide_current" ]; then
        echo "zoxide updated         : $zoxide_prev -> $zoxide_current"
    else
        echo "zoxide is up to date   : $zoxide_current"
    fi

    if [ "$kitty_prev" != "$kitty_current" ]; then
        echo "kitty updated          : $kitty_prev -> $kitty_current"
    else
        echo "kitty is up to date    : $kitty_current"
    fi
}

# Extracts any archive(s) (if unp isn't installed)
extract() {
	for archive in "$@"; do
		if [ -f "$archive" ]; then
			case $archive in
			*.tar.bz2) tar xvjf $archive ;;
			*.tar.gz) tar xvzf $archive ;;
			*.bz2) bunzip2 $archive ;;
			*.rar) rar x $archive ;;
			*.gz) gunzip $archive ;;
			*.tar) tar xvf $archive ;;
			*.tbz2) tar xvjf $archive ;;
			*.tgz) tar xvzf $archive ;;
			*.zip) unzip $archive ;;
			*.Z) uncompress $archive ;;
			*.7z) 7z x $archive ;;
			*) echo "don't know how to extract '$archive'..." ;;
			esac
		else
			echo "'$archive' is not a valid file!"
		fi
	done
}

# Searches for text in all files in the current folder
ftext() {
	# -i case-insensitive
	# -I ignore binary files
	# -H causes filename to be printed
	# -r recursive search
	# -n causes line number to be printed
	# optional: -F treat search term as a literal, not a regular expression
	# optional: -l only print filenames and not the matching lines ex. grep -irl "$1" *
	grep -iIHrn --color=always "$1" . | less -r
}

# Copy file with a progress bar
cpp() {
    set -e
    strace -q -ewrite cp -- "${1}" "${2}" 2>&1 |
    awk '{
        count += $NF
        if (count % 10 == 0) {
            percent = count / total_size * 100
            printf "%3d%% [", percent
            for (i=0;i<=percent;i++)
                printf "="
            printf ">"
            for (i=percent;i<100;i++)
                printf " "
            printf "]\r"
        }
    }
    END { print "" }' total_size="$(stat -c '%s' "${1}")" count=0
}

# Copy and go to the directory
cpg() {
	if [ -d "$2" ]; then
		cp "$1" "$2" && cd "$2"
	else
		cp "$1" "$2"
	fi
}

# Move and go to the directory
mvg() {
	if [ -d "$2" ]; then
		mv "$1" "$2" && cd "$2"
	else
		mv "$1" "$2"
	fi
}

# Create and go to the directory
mkdirg() {
	mkdir -p "$1"
	cd "$1"
}

# Goes up a specified number of directories  (i.e. up 4)
up() {
	local d=""
	limit=$1
	for ((i = 1; i <= limit; i++)); do
		d=$d/..
	done
	d=$(echo $d | sed 's/^\///')
	if [ -z "$d" ]; then
		d=..
	fi
	cd $d
}

# Automatically do an ls after each cd, z, or zoxide
cd ()
{
	if [ -n "$1" ]; then
		builtin cd "$@" && ls
	else
		builtin cd ~ && ls
	fi
}

# Returns the last 2 fields of the working directory
pwdtail() {
	pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# Show the current distribution
distribution () {
    local dtype="unknown"  # Default to unknown

    # Use /etc/os-release for modern distro identification
    if [ -r /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            fedora|rhel|centos)
                dtype="redhat"
                ;;
            sles|opensuse*)
                dtype="suse"
                ;;
            ubuntu|debian)
                dtype="debian"
                ;;
            gentoo)
                dtype="gentoo"
                ;;
            arch|manjaro)
                dtype="arch"
                ;;
            slackware)
                dtype="slackware"
                ;;
            *)
                # Check ID_LIKE only if dtype is still unknown
                if [ -n "$ID_LIKE" ]; then
                    case $ID_LIKE in
                        *fedora*|*rhel*|*centos*)
                            dtype="redhat"
                            ;;
                        *sles*|*opensuse*)
                            dtype="suse"
                            ;;
                        *ubuntu*|*debian*)
                            dtype="debian"
                            ;;
                        *gentoo*)
                            dtype="gentoo"
                            ;;
                        *arch*)
                            dtype="arch"
                            ;;
                        *slackware*)
                            dtype="slackware"
                            ;;
                    esac
                fi

                # If ID or ID_LIKE is not recognized, keep dtype as unknown
                ;;
        esac

    echo $dtype
}

DISTRIBUTION=$(distribution)
if [ "$DISTRIBUTION" = "redhat" ] || [ "$DISTRIBUTION" = "arch" ]; then
      alias cat='bat'
else
      alias cat='batcat'
fi 

# Show the current version of the operating system
ver() {
    local dtype
    dtype=$(distribution)

    case $dtype in
        "redhat")
            if [ -s /etc/redhat-release ]; then
                cat /etc/redhat-release
            else
                cat /etc/issue
            fi
            uname -a
            ;;
        "suse")
            cat /etc/SuSE-release
            ;;
        "debian")
            lsb_release -a
            ;;
        "gentoo")
            cat /etc/gentoo-release
            ;;
        "arch")
            cat /etc/os-release
            ;;
        "slackware")
            cat /etc/slackware-version
            ;;
        *)
            if [ -s /etc/issue ]; then
                cat /etc/issue
            else
                echo "Error: Unknown distribution"
                exit 1
            fi
            ;;
    esac
}
alias distro="ver"

# IP address lookup
alias whatismyip="whatsmyip"
function whatsmyip () {
    # Function to check and print IP for a given interface
    print_ip() {
        local interface=$1
        local display_name=$2
        local ip_address=""
        
        if ip addr show "$interface" &> /dev/null; then
            ip_address=$(ip addr show "$interface" | grep "inet " | awk '{print $2}' | cut -d/ -f1)
        elif ifconfig "$interface" &> /dev/null; then
            ip_address=$(ifconfig "$interface" | grep "inet " | awk '{print $2}')
        fi

        if [ -n "$ip_address" ]; then
            echo "$display_name: $ip_address"
        fi
    }

    # Check and print IPs for eth0, eth1, and wlan0
    print_ip "eth0"  " eth0"
    print_ip "eth1"  " eth1"
    print_ip "wlan0" "wlan0"

    # External IP Lookup
    echo -n "  WAN: "
    curl -s ifconfig.me
}

# Trim leading and trailing spaces (for scripts)
trim() {
	local var=$*
	var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace characters
	var="${var%"${var##*[![:space:]]}"}" # remove trailing whitespace characters
	echo -n "$var"
}
# GitHub Titus Additions

gcom() {
	git add .
	git commit -m "$1"
}
lazyg() {
	git add .
	git commit -m "$1"
	git push
}
rebase() {
    git rebase -i HEAD~"$1"
}

#######################################################
# Set the ultimate amazing command prompt
#######################################################

# Check if the shell is interactive
if [[ $- == *i* ]]; then
    # Bind Ctrl+f to insert 'zi' followed by a newline
    bind '"\C-f":"zi\n"'
fi

export PATH=$PATH:"$HOME/.local/bin"

eval "$(starship init bash)"
eval "$(zoxide init bash)"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
