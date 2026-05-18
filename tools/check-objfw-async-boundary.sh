#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

matches=$(
    rg -n '\basync[A-Z][A-Za-z0-9_]*:' \
        --glob '!AsyncRT/Vendor/**' \
        --glob '!notes/**' \
        --glob '!build*/**' \
        . || true
)

violations=$(
    printf '%s\n' "$matches" \
        | rg -v '^\./AsyncRT/Core/AsyncScheduler\.m:' \
        | rg -v '^\./AsyncRT/Core/AsyncStreamTasks\.m:' \
        | rg -v '^\./AsyncRT/Networking/HTTP/AsyncHTTPClient\.m:' \
        | rg -v 'asyncApplication[A-Za-z0-9_]*:' \
        | rg -v 'asyncHandler:' \
        | rg -v '^$' || true
)

if [ -n "$violations" ]; then
    printf '%s\n' "ObjFW async boundary violations:"
    printf '%s\n' "$violations"
    exit 1
fi

printf '%s\n' "ObjFW async boundary check passed."
