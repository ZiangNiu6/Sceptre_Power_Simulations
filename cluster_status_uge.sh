#!/usr/bin/env bash
# cluster_status_uge.sh
# Usage:  cluster_status_uge.sh <jobid>
jid="$1"

# When job is still in qstat it is running or pending
if qstat -j "$jid" &>/dev/null; then
    echo "running"
    exit 0
fi

# Job not in qstat - try qacct with retries to handle timing gap
for i in {1..10}; do
    exit_status=$(qacct -j "$jid" 2>/dev/null | awk '/^exit_status/ {print $NF}')
    
    if [[ -n "$exit_status" ]]; then
        if [[ "$exit_status" -eq 0 ]]; then
            echo "success"
        else
            echo "failed"
        fi
        exit 0
    fi
    
    # Wait 3 seconds before retry
    sleep 3
done

# If still no accounting record after 30 seconds, assume failed
echo "failed"