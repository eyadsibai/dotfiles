# Local Codex usage compatibility fix

Installed September 22, 2026, for Codex CLI 0.155.1.

The packaged Omarchy collector starts `codex -s read-only -a untrusted app-server`.
This Codex rejects `untrusted`, so the panel reported `Codex limits unavailable`
with `initialize` as the authentication help text, even with a valid login.

This user-owned clone changes only the collection launcher in `Main.qml`.
`bin/refresh-usage` resolves the installed Codex executable, resolving mise
shims with `mise which codex`, then prepends a private compatibility directory
to the collector's PATH. `bin/compat/codex` translates only that exact five-argument
probe to `-s read-only -a on-request app-server`. Other arguments and exit codes
pass through unchanged. Desktop and terminal PATH values remain unchanged.

The installed collectors, account credentials, and packaged Omarchy files are
unchanged. Claude and other provider collection still uses the packaged updater.
The local clone replaces `omarchy.agents` as `eyad.agents`; it keeps the existing
panel appearance, settings, and IPC target. Like any local Omarchy clone, its QML
does not automatically receive later changes to the packaged plugin.

Validation:

- The original invocation failed with `invalid value 'untrusted'`.
- `tests/codex-compat.sh` covers the translated probe, unchanged supported probe,
  unrelated arguments, exit status, and mise resolution. Each new behavior was
  checked failing before its fix and passing afterward.
- Bash syntax and `omarchy plugin validate` checks pass.
- The launcher returns a live Pro plan and weekly limits with the desktop PATH.
- ShellCheck is not installed on this machine.

Run checks with `bash tests/codex-compat.sh` from this directory.
To return to the packaged widget after it gains compatibility, run
`omarchy plugin enable omarchy.agents`. The original shell configuration is
backed up at `~/.config/omarchy/shell.json.before-codex-usage-fix-20260922`.
