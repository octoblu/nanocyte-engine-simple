#!/bin/bash

# /flows//instances/

# HOST="https://nanocyte-engine.octoblu.com"
PROTOCOL="http://"
HOST="localhost:5050"
# HOST="172.17.8.101:5050"

FLOW_UUID=bf3fbc43-c90b-4e0d-a609-6f58caed29d9
FLOW_TOKEN=5a1f5d795cde22c982d61655d2d59a44b0495c2c
INSTANCE_UUID=f332e9d7-7f98-4f8e-89e1-6f069d8e8572
TRIGGER_UUID=f84bd7f0-6bb9-11e5-ae86-6b89656e6b1a

URL="${PROTOCOL}${FLOW_UUID}:${FLOW_TOKEN}@${HOST}/flows/${FLOW_UUID}/instances/${INSTANCE_UUID}/messages"
DATA='{"devices": ["'$FLOW_UUID'"], "topic": "button", "payload": {"from": "'$TRIGGER_UUID'", "foo": [1,2,3]}}'
curl -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
