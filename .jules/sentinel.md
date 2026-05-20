## 2024-05-17 - [Command Injection via Unquoted Shell Variables]
**Vulnerability:** Unquoted variables in shell functions (e.g., `curlhammer`, `curlheader`) allowed command injection if user-provided input contained shell metacharacters.
**Learning:** Even utility functions in dotfiles can be vulnerable if they interact with commands like `curl` without proper quoting.
**Prevention:** Always wrap shell variables in double quotes when passed as arguments to commands.

## 2024-05-17 - [Infinite Loop in Maintenance Script]
**Vulnerability:** `scripts/delete_files.sh` used a `while true` loop with `find ... -delete` as a condition. Since `find` returns success even when no files are found, this resulted in an infinite loop.
**Learning:** Relying on `find`'s exit code for loop termination is unreliable for checking if files were actually found/processed.
**Prevention:** Use `grep -q .` on the output of `find` or similar commands to verify if work was actually performed.

## 2024-05-18 - [Command Injection in Arithmetic Expansion]
**Vulnerability:** Unvalidated variables used in shell arithmetic expansion `((i=1; i<=$var; i++))` allowed command injection in `curlhammer`.
**Learning:** Quoting variables is not enough in arithmetic contexts; they must be explicitly validated as integers.
**Prevention:** Use a regex like `[[ "$var" =~ ^[0-9]+$ ]]` to validate integer inputs before use in arithmetic expansion.

## 2024-05-18 - [Command Injection in tmux session creation]
**Vulnerability:** Unquoted arguments in `oc()` were passed to `tmux new-session`, leading to command injection when tmux executed the command string.
**Learning:** Functions that wrap complex commands like `tmux` or `eval` require careful escaping of all arguments.
**Prevention:** Use `printf %q` to escape arguments and be wary of double expansion when the escaped string is used inside another quoted string.
