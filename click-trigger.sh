#!/bin/bash

# /flows//instances/
#URL="http://nanocyte-engine.octoblu.com/flows/$FLOW_UUID/instances/$INSTANCE_UUID/messages"


FLOW_UUID=c36f335a-d820-42bc-bedb-b08775931318
INSTANCE_UUID=e9edd9c9-5793-4581-af1c-8f50caa28107
TRIGGER_UUID=9f7242a0-621c-11e5-b85f-0b844c991eb6

URL="http://localhost:5050/flows/$FLOW_UUID/instances/$INSTANCE_UUID/messages"
DATA='{"devices": ["'$FLOW_UUID'"], "topic": "button", "payload": {"from": "'$TRIGGER_UUID'", "foo": [1,2,3]}}'
curl -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"

