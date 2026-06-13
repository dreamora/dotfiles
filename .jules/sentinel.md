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

## 2026-06-12 - [Arithmetic Injection and Option Injection in Shell Functions]
**Vulnerability:** Shell functions like `curlhammer` were vulnerable to arithmetic injection via unvalidated variables in C-style for-loops `((i=1; i<=$var; i++))`. Additionally, many functions were vulnerable to option injection because they didn't use the `--` delimiter when passing user-provided input to commands like `curl` or `grep`.
**Learning:** Quoting is not enough to prevent arithmetic injection; strict integer validation is required. The `--` delimiter is essential for commands that accept user-provided strings as positional arguments to prevent them from being interpreted as flags.
**Prevention:** Use `[[ "$var" =~ ^[0-9]+$ ]]` for integer validation. Always use `--` before positional arguments in CLI tools.
