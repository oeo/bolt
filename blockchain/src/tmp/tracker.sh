#!/bin/bash

LATEST_CID_FILE="latest_cid.txt"
NODES_OUTPUT_FILE="latest_nodes.txt"

NODE_IP=$(curl -s ipv4.icanhazip.com)

if [ -f "$LATEST_CID_FILE" ]; then
    PREVIOUS_CID=$(cat "$LATEST_CID_FILE")
else
    PREVIOUS_CID=null
fi

# Updated date command for compatibility
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_ENTRY=$(jq -n \
                --arg ip "$NODE_IP" \
                --arg prevCID "$PREVIOUS_CID" \
                --arg time "$TIMESTAMP" \
                '{timestamp: $time, nodes: [$ip], previousCID: $prevCID}')

NEW_CID=$(echo "$LOG_ENTRY" | ipfs add -Q)

echo "$NEW_CID" > "$LATEST_CID_FILE"

echo "Log entry updated. New CID: $NEW_CID"

# Retrieve the latest log entry from IPFS and output the nodes to a file
ipfs cat "$NEW_CID" | jq -r '.nodes | .[]' > "$NODES_OUTPUT_FILE"

echo "Latest nodes have been output to $NODES_OUTPUT_FILE"

