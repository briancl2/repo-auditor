#!/usr/bin/env bash
# run-with-timeout.sh — Run a command under a wall-clock budget.
#
# Bounds any single command so a slow or hung child can never stall a caller
# indefinitely. Resolution order:
#   1. GNU coreutils `timeout` (or `gtimeout` on macOS) when on PATH.
#   2. `perl` alarm-based watchdog (perl ships with macOS, so the sweep stays
#      bounded even when coreutils is not installed).
#   3. Best-effort unbounded run when neither is available (documented
#      degradation — the wrapper never fails the caller just for lacking a
#      timeout binary).
#
# Usage: bash scripts/run-with-timeout.sh <seconds> <command> [args...]
#
# Exit codes:
#   124 — command exceeded the budget and was terminated (fail-fast signal)
#   *   — the command's own exit code otherwise
set -euo pipefail

SECONDS_BUDGET="${1:?Usage: run-with-timeout.sh <seconds> <command> [args...]}"
shift
if [ "$#" -eq 0 ]; then
    echo "ERROR: run-with-timeout.sh requires a command to run" >&2
    exit 2
fi

TIMEOUT_BIN="timeout"
if ! command -v "$TIMEOUT_BIN" >/dev/null 2>&1; then
    TIMEOUT_BIN="gtimeout"
fi

if command -v "$TIMEOUT_BIN" >/dev/null 2>&1; then
    # -k gives the child a short grace period after SIGTERM before SIGKILL so a
    # well-behaved child can flush, but a truly wedged child is still reaped.
    exec "$TIMEOUT_BIN" -k 5 "$SECONDS_BUDGET" "$@"
fi

if command -v perl >/dev/null 2>&1; then
    # Fork the command, arm an alarm at the budget, SIGTERM on expiry, then
    # SIGKILL 5s later if it ignores TERM. Returns 124 on timeout, the child's
    # own exit code otherwise, or 128+signal if the child died from a signal.
    exec perl -e '
        my $t = shift @ARGV;
        my $pid = fork();
        defined $pid or die "run-with-timeout: fork failed: $!\n";
        if ($pid == 0) { exec { $ARGV[0] } @ARGV; exit 127; }
        my $timed_out = 0;
        $SIG{ALRM} = sub {
            if (!$timed_out) { $timed_out = 1; kill "TERM", $pid; alarm 5; }
            else { kill "KILL", $pid; }
        };
        alarm $t;
        waitpid($pid, 0);
        my $status = $?;
        alarm 0;
        exit 124 if $timed_out;
        exit(($status & 127) ? 128 + ($status & 127) : ($status >> 8));
    ' "$SECONDS_BUDGET" "$@"
fi

# No timeout mechanism available: run unbounded (documented best-effort).
exec "$@"
