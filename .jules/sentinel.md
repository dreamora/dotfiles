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

## 2024-06-17 - [Arithmetic Injection in Shell Arithmetic Expansion]
**Vulnerability:** Shell arithmetic expansion `(( ))` or `$(( ))` can be exploited for command execution via array index evaluation (e.g., `a[$(id)0]`) if user-provided variables are not strictly validated as integers.
**Learning:** Quoting does not protect against this; only strict regex-based integer validation (`[[ "$var" =~ ^[0-9]+$ ]]`) is effective.
**Prevention:** Always validate user-provided variables used in arithmetic contexts as integers before use.

## 2025-01-24 - [Regression: Unused Escaped Variables in Tmux Commands]
**Vulnerability:** A previous fix for the `oc` function prepared an `args_escaped` variable using `printf %q` but failed to actually use it in the `tmux new-session` command, continuing to use the vulnerable `$*`.
**Learning:** Security fixes must be verified not only for their presence but for their actual integration into the execution path. Unused security variables provide no protection.
**Prevention:** Always verify that prepared security-hardened variables are correctly referenced in the final command construction.

## 2026-06-20 - [Command and Option Injection in Shell Utilities]
**Vulnerability:** The `manp` function in `homedir/.shellfn` was vulnerable to argument splitting/globbing and option injection because it passed `$1` to `man` unquoted and without a delimiter. Other functions like `curltime` and `tre` were vulnerable to option injection because they lacked the `--` delimiter for user-provided URLs/paths.
**Learning:** Quoting prevents word splitting/globbing; the `--` delimiter prevents malicious input from being interpreted as command-line options for tools that support it.
**Prevention:** Always quote user-provided variables, and use `--` with CLIs that support it; for tools that don’t, use tool-specific safe forms (e.g., prefix `./` for 7-Zip paths starting with `-`).
## 2025-05-14 - [Command and Option Injection in manp function]
**Vulnerability:** The `manp` function in `homedir/.shellfn` used an unquoted `$1` variable in the `man` command, allowing for argument splitting and potential command injection if combined with other vulnerabilities. It also lacked the `--` delimiter, making it vulnerable to option injection.
**Learning:** Even simple wrapper functions for standard commands like `man` must be hardened with proper quoting and delimiters to prevent malicious input from altering command behavior.
**Prevention:** Always use double quotes `"$1"` and the `--` delimiter when passing user-provided input as a positional argument to a command.

## 2025-05-15 - [Absolute Path Regression in Option Injection Fix]
**Vulnerability:** Unconditionally prefixing a path variable with `./` to prevent option injection in `find` (e.g., `find "./$dir"`) breaks support for absolute paths.
**Learning:** Security fixes that alter path strings must account for the difference between relative and absolute paths to avoid breaking standard tool behavior.
**Prevention:** Use a conditional check to only prefix paths starting with a dash (e.g., `[[ "$path" == -* ]] && path="./$path"`).
