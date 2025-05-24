<!--
SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>

SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Adding Yod to the PATH

### Microsoft Windows systems

1. Right-click on the Start button and select “System”
2. Click on “Advanced system settings” on the right side
3. Click on the “Environment Variables” button
4. Under “System variables”, find and select the “Path” variable, then click “Edit”
5. Click “New” and add the full path to the folder containing the Yod executable
6. Click “OK” to close each window
7. Restart any open command prompt windows to apply the changes

### Unix-like systems

1. Open a terminal
2. Determine which shell you’re using by running `echo $SHELL`
3. Edit the appropriate configuration file and add the following line, replacing `/path/to/yod/executable/directory` with the actual path:

   For Bash (`~/.bash_profile` or `~/.bashrc`):

   ```bash
   export PATH="$PATH:/path/to/yod/executable/directory"
   ```

   For Zsh (`~/.zshrc`):

   ```zsh
   path+=('/path/to/yod/executable/directory')
   export PATH
   ```

   For Fish (`~/.config/fish/config.fish`):

   ```fish
   set -U fish_user_paths /path/to/yod/executable/directory $fish_user_paths
   ```

4. Save the file and exit the editor
5. Restart your terminal, or run:

   ```sh
   source ~/.bash_profile
   source ~/.zshrc
   source ~/.config/fish/config.fish
   ```

> [!NOTE]
> If you’re using a different shell, consult its documentation for the correct configuration file and method to update the PATH.

After following these steps, you should be able to run the `yod` command from any directory in your terminal or command prompt.
