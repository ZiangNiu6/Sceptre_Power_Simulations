#!/usr/bin/env bash
# cluster_status_uge.sh
# Usage:  cluster_status_uge.sh <jobid>
jid="$1"

# When job is still in qstat it is running or pending
if qstat -j "$jid" &>/dev/null; then
    echo "running"
    exit 0
fi

# Otherwise it has finished → use qacct (needs some seconds after end)
exit_status=$(qacct -j "$jid" 2>/dev/null | awk '/exit_status/ {print $2}')

if [[ -z "$exit_status" ]]; then
    # accounting record not written yet → assume still running
    echo "running"
elif [[ "$exit_status" -eq 0 ]]; then
    echo "success"
else
    echo "failed"
fi