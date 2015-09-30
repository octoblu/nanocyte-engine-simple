#!/bin/bash

# /flows//instances/

# HOST="https://nanocyte-engine.octoblu.com"
PROTOCOL="http://"
HOST="localhost:5050"

FLOW_UUID=c36f335a-d820-42bc-bedb-b08775931318
FLOW_TOKEN=f2b8a16f2ef7044f99480d00ee078f031edb66cb
INSTANCE_UUID=24700c38-f1cb-475b-8191-403c5a582578
TRIGGER_UUID=f0a24f30-65f5-11e5-9e93-15a2079176fa

URL="${PROTOCOL}${FLOW_UUID}:${FLOW_TOKEN}@${HOST}/flows/${FLOW_UUID}/instances/${INSTANCE_UUID}/messages"
DATA='{"devices": ["'$FLOW_UUID'"], "topic": "button", "payload": {"from": "'$TRIGGER_UUID'", "foo": [1,2,3]}}'
curl -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
