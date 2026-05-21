## 2024-05-17 - [Command Injection via Unquoted Shell Variables]
**Vulnerability:** Unquoted variables in shell functions (e.g., `curlhammer`, `curlheader`) allowed command injection if user-provided input contained shell metacharacters.
**Learning:** Even utility functions in dotfiles can be vulnerable if they interact with commands like `curl` without proper quoting.
**Prevention:** Always wrap shell variables in double quotes when passed as arguments to commands.

## 2024-05-17 - [Infinite Loop in Maintenance Script]
**Vulnerability:** `scripts/delete_files.sh` used a `while true` loop with `find ... -delete` as a condition. Since `find` returns success even when no files are found, this resulted in an infinite loop.
**Learning:** Relying on `find`'s exit code for loop termination is unreliable for checking if files were actually found/processed.
**Prevention:** Use `grep -q .` on the output of `find` or similar commands to verify if work was actually performed.

## 2024-05-17 - [Command Injection in tmux session creation]
**Vulnerability:** Passing unquoted shell variables to commands that perform secondary evaluation (like `tmux new-session "..."`) allows for command injection.
**Learning:** When a command evaluates its arguments as a shell command (e.g., `tmux`, `ssh`, `eval`), simple quoting in the parent shell is insufficient to protect against malicious input in the subshell.
**Prevention:** Use `printf %q` to safely escape arguments before including them in a command string that will be re-evaluated by a subshell.
