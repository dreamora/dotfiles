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

## 2024-10-24 - [Arithmetic Injection in Shell Loops]
**Vulnerability:** User-controlled variables used in shell arithmetic expansions `(( ))` (e.g., in `for` loops) were not validated. This allowed arbitrary command execution via array index evaluation (e.g., `a[$(cmd)0]`).
**Learning:** Double-quoting shell variables is insufficient to prevent injection in arithmetic contexts.
**Prevention:** Always validate user-provided variables as integers using a regex like `[[ "$var" =~ ^[0-9]+$ ]]` before using them in arithmetic expansions.

## 2024-10-24 - [Option Injection in CLI Utilities]
**Vulnerability:** Shell functions passing user input to tools like `curl`, `grep`, or `man` without the `--` delimiter were vulnerable to option injection (e.g., inputting `-u` to `curl`).
**Learning:** Even if a variable is quoted, it can still be interpreted as a command-line flag if it starts with a hyphen.
**Prevention:** Use the `--` delimiter to explicitly mark the end of options and the beginning of positional arguments when passing user-controlled data to CLI tools.
