## Overview of ChrisTitusTech's `.bashrc` Configuration

The `.bashrc` file is a script that runs every time a new terminal session is started in Unix-like operating systems. It is used to configure the shell session, set up aliases, define functions, and more, making the terminal easier to use and more powerful. Below is a summary of the key sections and functionalities defined in the provided `.bashrc` file.

## How to install

```
curl -sS https://raw.githubusercontent.com/yuri-rage/mybash/yuri-bash/setup.sh | sh
```

OR

```
git clone --depth=1 https://github.com/yuri-rage/mybash.git
cd mybash
git checkout yuri-bash
chmod +x setup.sh
./setup.sh
```

### To update un-managed packages

Several apps/binaries are installed by `setup.sh` that are not managed by the package manager. Run `update-mybash` (defined in `.bashrc`) to update them.

### To run kitty in WSL via a Windows shortcut

Create a shortcut with the following target:

```
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -Command C:\Windows\System32\wsl.exe --cd ~ -e bash -c /home/yuri/.local/bin/kitty
```

Replace "yuri" with your username.

### Initial Setup and System Checks

- **Environment Checks**: The script checks if it is running in an interactive mode and sets up the environment accordingly.
- **System Utilities**: It checks for the presence of utilities like `fastfetch`, `bash-completion`, and system-specific configurations (`/etc/bashrc`).

### Aliases and Functions

- **Aliases**: Shortcuts for common commands are set up to enhance productivity. For example, `alias cp='cp -i'` makes the `cp` command interactive, asking for confirmation before overwriting files.
- **Functions**: Custom functions for complex operations like `extract()` for extracting various archive types, and `cpp()` for copying files with a progress bar.

### Prompt Customization and History Management

- **Prompt Command**: The `PROMPT_COMMAND` variable is set to automatically save the command history after each command.
- **History Control**: Settings to manage the size of the history file and how duplicates are handled.

### System-Specific Aliases and Settings

- **Editor Settings**: Sets `nvim` (NeoVim) as the default editor.
- **Conditional Aliases**: Depending on the system type (like Fedora), it sets specific aliases, e.g., replacing `cat` with `bat`.

### Enhancements and Utilities

- **Color and Formatting**: Enhancements for command output readability using colors and formatting for tools like `ls`, `grep`, and `man`.
- **Navigation Shortcuts**: Aliases to simplify directory navigation, e.g., `alias ..='cd ..'` to go up one directory.
- **Safety Features**: Aliases for safer file operations, like using `trash` instead of `rm` for deleting files, to prevent accidental data loss.
- **Extensive Zoxide support**: Easily navigate with `z`, `zi`, or pressing Ctrl+f to launch zi to see frequently used navigation directories.

### Advanced Functions

- **System Information**: Functions to display system information like `distribution()` to identify the Linux distribution.
- **Networking Utilities**: Tools to check internal and external IP addresses.
- **Resource Monitoring**: Commands to monitor system resources like disk usage and open ports.

### Installation and Configuration Helpers

- **Auto-Install**: A function `install_bashrc_support()` to automatically install necessary utilities based on the system type.
- **Configuration Editors**: Functions to edit important configuration files directly, e.g., `apacheconfig()` for Apache server configurations.

### Conclusion

This `.bashrc` file is a comprehensive setup that not only enhances the shell experience with useful aliases and functions but also provides system-specific configurations and safety features to cater to different user needs and system types. It is designed to make the terminal more user-friendly, efficient, and powerful for an average user.

