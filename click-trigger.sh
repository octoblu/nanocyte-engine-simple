#!/bin/bash

# /flows//instances/

HOST="https://nanocyte-engine.octoblu.com"
#HOST="http://localhost:5050"

FLOW_UUID=c36f335a-d820-42bc-bedb-b08775931318
INSTANCE_UUID=abaa99d0-081f-4967-a8fe-dada9e0c6754
TRIGGER_UUID=9f7242a0-621c-11e5-b85f-0b844c991eb6

URL="$HOST/flows/$FLOW_UUID/instances/$INSTANCE_UUID/messages"
DATA='{"devices": ["'$FLOW_UUID'"], "topic": "button", "payload": {"from": "'$TRIGGER_UUID'", "foo": [1,2,3]}}'
curl -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
