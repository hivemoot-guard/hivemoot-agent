#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_fails_with() {
  local expected="$1"
  shift

  local stderr_file
  stderr_file="$(mktemp)"
  if "$@" > /dev/null 2> "$stderr_file"; then
    rm -f "$stderr_file"
    fail "command succeeded unexpectedly: $*"
  fi

  if ! grep -Fqx "$expected" "$stderr_file"; then
    echo "Expected stderr line:" >&2
    echo "  $expected" >&2
    echo "Actual stderr:" >&2
    sed 's/^/  /' "$stderr_file" >&2
    rm -f "$stderr_file"
    fail "stderr mismatch for: $*"
  fi

  rm -f "$stderr_file"
}

echo "Running run-loop backoff validation checks"

assert_fails_with \
  "periodic_agent_failure_backoff_base_secs must be a non-negative integer" \
  env -u TARGET_REPO PERIODIC_AGENT_FAILURE_BACKOFF_BASE_SECS=abc bash scripts/run-loop.sh

assert_fails_with \
  "PERIODIC_AGENT_FAILURE_BACKOFF_BASE_SECS must be > 0" \
  env -u TARGET_REPO PERIODIC_AGENT_FAILURE_BACKOFF_BASE_SECS=0 bash scripts/run-loop.sh

assert_fails_with \
  "PERIODIC_AGENT_FAILURE_BACKOFF_MAX_SECS must be > 0" \
  env -u TARGET_REPO PERIODIC_AGENT_FAILURE_BACKOFF_MAX_SECS=0 bash scripts/run-loop.sh

assert_fails_with \
  "PERIODIC_AGENT_FAILURE_BACKOFF_MAX_SECS must be >= PERIODIC_AGENT_FAILURE_BACKOFF_BASE_SECS" \
  env -u TARGET_REPO PERIODIC_AGENT_FAILURE_BACKOFF_BASE_SECS=10 PERIODIC_AGENT_FAILURE_BACKOFF_MAX_SECS=9 bash scripts/run-loop.sh

assert_fails_with \
  "PERIODIC_AGENT_FAILURE_BACKOFF_JITTER_PCT must be <= 100" \
  env -u TARGET_REPO PERIODIC_AGENT_FAILURE_BACKOFF_JITTER_PCT=101 bash scripts/run-loop.sh

echo "PASS: run-loop backoff validation checks"
