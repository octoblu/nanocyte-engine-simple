#!/bin/bash

# /flows//instances/

# HOST="https://nanocyte-engine.octoblu.com"
PROTOCOL="http://"
HOST="localhost:5050"
# HOST="172.17.8.101:5050"

FLOW_UUID=bf3fbc43-c90b-4e0d-a609-6f58caed29d9
FLOW_TOKEN=5a1f5d795cde22c982d61655d2d59a44b0495c2c
INSTANCE_UUID=8c9135f5-c48f-4008-8a41-af22599476eb
TRIGGER_UUID=31503d60-678d-11e5-a99e-3566d24dacf2

URL="${PROTOCOL}${FLOW_UUID}:${FLOW_TOKEN}@${HOST}/flows/${FLOW_UUID}/instances/${INSTANCE_UUID}/messages"
DATA='{"devices": ["'$FLOW_UUID'"], "topic": "button", "payload": {"from": "'$TRIGGER_UUID'", "foo": [1,2,3]}}'
curl -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
