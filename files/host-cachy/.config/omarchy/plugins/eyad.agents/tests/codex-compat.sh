#!/bin/bash
set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT

cat > "$scratch/codex" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" > "$CODEX_TEST_ARGS"
exit "${CODEX_TEST_EXIT:-0}"
EOF
chmod +x "$scratch/codex"
export OMARCHY_USAGE_CODEX="$scratch/codex"
export CODEX_TEST_ARGS="$scratch/args"

"$plugin_dir/bin/compat/codex" -s read-only -a untrusted app-server
expected=$'-s\nread-only\n-a\non-request\napp-server'
[[ $(cat "$CODEX_TEST_ARGS") == "$expected" ]]
echo 'PASS: the read-only usage probe uses the supported approval setting'

"$plugin_dir/bin/compat/codex" -s read-only -a on-request app-server
[[ $(cat "$CODEX_TEST_ARGS") == "$expected" ]]
echo 'PASS: the supported usage command stays unchanged'

"$plugin_dir/bin/compat/codex" -s read-only -a untrusted exec 'a quoted argument'
expected=$'-s\nread-only\n-a\nuntrusted\nexec\na quoted argument'
[[ $(cat "$CODEX_TEST_ARGS") == "$expected" ]]
echo 'PASS: other Codex commands and argument boundaries stay unchanged'

export CODEX_TEST_EXIT=23
status=0
"$plugin_dir/bin/compat/codex" --version || status=$?
[[ $status == 23 ]]
echo 'PASS: Codex exit status is preserved'

unset CODEX_TEST_EXIT
mkdir "$scratch/shims"
cat > "$scratch/shims/mise" <<'EOF'
#!/bin/bash
[[ $# == 2 && $1 == which && $2 == codex ]] || exit 24
printf '%s\n' "$CODEX_TEST_REAL"
EOF
ln -s mise "$scratch/shims/codex"
cat > "$scratch/shims/omarchy-agent-usage-update" <<'EOF'
#!/bin/bash
codex -s read-only -a untrusted app-server
EOF
chmod +x "$scratch/shims/mise" "$scratch/shims/omarchy-agent-usage-update"
export CODEX_TEST_REAL="$scratch/codex"
PATH="$scratch/shims:$PATH" "$plugin_dir/bin/refresh-usage" --limits-only codex
expected=$'-s\nread-only\n-a\non-request\napp-server'
[[ $(cat "$CODEX_TEST_ARGS") == "$expected" ]]
echo 'PASS: the launcher resolves mise shims before starting the probe'
