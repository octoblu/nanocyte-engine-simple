#!/bin/bash

# /flows//instances/
#URL="http://nanocyte-engine.octoblu.com/flows/$FLOW_UUID/instances/$INSTANCE_UUID/messages"


FLOW_UUID=c36f335a-d820-42bc-bedb-b08775931318
INSTANCE_UUID=338b79a0-475c-45dd-a4d7-334e866e9911
TRIGGER_UUID=9f7242a0-621c-11e5-b85f-0b844c991eb6

URL="http://localhost:5050/flows/$FLOW_UUID/instances/$INSTANCE_UUID/messages"
DATA='{"devices": ["'$FLOW_UUID'"], "topic": "button", "payload": {"from": "'$TRIGGER_UUID'", "foo": [1,2,3]}}'
curl -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
