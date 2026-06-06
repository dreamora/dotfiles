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

## 2024-06-04 - [Arithmetic Injection via User-Controlled Variables]
**Vulnerability:** Shell arithmetic expansion `(( ))` or `$[ ]` evaluates variables as expressions. If a variable is user-controlled and unvalidated, it can trigger command execution via array index evaluation (e.g., `a[$(id)]`).
**Learning:** Quoting variables is insufficient to prevent injection within arithmetic contexts in Bash.
**Prevention:** Always validate that variables used in shell arithmetic are strictly integers using a regex like `[[ "$var" =~ ^[0-9]+$ ]]`.

## 2024-06-04 - [Option Injection in Shell Utilities]
**Vulnerability:** Functions that pass user-supplied arguments directly to CLI tools (like `curl`, `man`, `grep`, `mkdir`) were vulnerable to option injection if the input started with a dash (e.g., `gitnr -p`).
**Learning:** Standard shell utilities often interpret leading dashes as options unless the `--` delimiter is used.
**Prevention:** Use the `--` delimiter before passing user-controlled variables as positional arguments to CLI commands. Ensure variables are double-quoted.
