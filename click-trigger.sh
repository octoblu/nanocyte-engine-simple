#!/bin/bash

# /flows//instances/

# HOST="https://nanocyte-engine.octoblu.com"
PROTOCOL="http://"
HOST="localhost:5050"
# HOST="172.17.8.101:5050"

FLOW_UUID=a2d0ba1a-a0f3-4f2c-9062-14cd3e9c5ffe
FLOW_TOKEN=58254f979311c4fb27bbb579751cd6863695573e
INSTANCE_UUID=$1
TRIGGER_UUID=2303e740-6dfd-11e5-bde0-6bdc4f7956bb

URL="${PROTOCOL}${FLOW_UUID}:${FLOW_TOKEN}@${HOST}/flows/${FLOW_UUID}/instances/${INSTANCE_UUID}/messages"
DATA='{"devices": ["'$FLOW_UUID'"], "topic": "button", "payload": {"from": "'$TRIGGER_UUID'", "foo": "bar"}}'
curl -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
