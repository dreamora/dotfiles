## 2024-05-17 - [Command Injection via Unquoted Shell Variables]
**Vulnerability:** Unquoted variables in shell functions (e.g., `curlhammer`, `curlheader`) allowed command injection if user-provided input contained shell metacharacters.
**Learning:** Even utility functions in dotfiles can be vulnerable if they interact with commands like `curl` without proper quoting.
**Prevention:** Always wrap shell variables in double quotes when passed as arguments to commands.

## 2024-05-17 - [Infinite Loop in Maintenance Script]
**Vulnerability:** `scripts/delete_files.sh` used a `while true` loop with `find ... -delete` as a condition. Since `find` returns success even when no files are found, this resulted in an infinite loop.
**Learning:** Relying on `find`'s exit code for loop termination is unreliable for checking if files were actually found/processed.
**Prevention:** Use `grep -q .` on the output of `find` or similar commands to verify if work was actually performed.

## 2024-06-03 - [Command Injection via Secondary Shell Evaluation in Tmux]
**Vulnerability:** The `oc` function in `homedir/.shellfn` constructed a command string for `tmux new-session` using unquoted `$*`. This allowed command injection because the string was evaluated by a secondary shell spawned by tmux.
**Learning:** Functions that wrap commands like `tmux` or `eval` which perform their own shell evaluation are doubly at risk. Standard quoting protects against the first shell but not the second.
**Prevention:** Use `printf %q` to escape arguments that will be evaluated by a secondary shell, ensuring they are treated as literal strings in the subshell context.

## 2024-06-01 - [Comprehensive Shell Hardening in .shellfn]
**Vulnerability:** Multiple functions in `homedir/.shellfn` were vulnerable to command and option injection. Specifically, `curlhammer` was vulnerable to injection in arithmetic expansion `(( ))`, `kill_on_port` in `lsof` arguments, and various curl-based functions to option injection via malicious URLs/headers.
**Learning:** Shell arithmetic expansion is an often-overlooked injection vector where shell metacharacters in a variable can trigger command execution even if the variable is not used in a typical "command" position.
**Prevention:** Always use strict regex validation for variables used in arithmetic contexts (e.g., `[[ "$var" =~ ^[0-9]+$ ]]`). Use `--` to terminate option parsing when passing user-controlled strings to CLI tools like `curl` or `grep`.
