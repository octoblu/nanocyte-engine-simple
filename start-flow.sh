#!/bin/bash

# /flows//instances/

UUID=dd3d787a-7833-4581-9287-3ad2c5a1273a
INSTANCE_UUID=fcdd26a0-5d65-11e5-9fc2-63ce49df012b

DATA='{"devices": ["dd3d787a-7833-4581-9287-3ad2c5a1273a"], "topic": "button", "payload": {"from": "8a8da890-55d6-11e5-bd83-1349dc09f6d6", "foo": "bar"}}'
URL="http://localhost:5050/flows/$UUID/instances/$INSTANCE_UUID/messages"
curl -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
