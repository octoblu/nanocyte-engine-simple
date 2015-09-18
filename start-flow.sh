#!/bin/bash

# /flows//instances/

UUID=dd3d787a-7833-4581-9287-3ad2c5a1273a
INSTANCE_UUID=c9714100-5e52-11e5-9452-e11abdd489be

DATA='{"devices": ["dd3d787a-7833-4581-9287-3ad2c5a1273a"], "topic": "button", "payload": {"from": "abfab830-5d9a-11e5-a513-13ce059e4cb9", "foo": "bar"}}'
URL="http://nanocyte-engine.octoblu.com/flows/$UUID/instances/$INSTANCE_UUID/messages"
#URL="http://localhost:5050/flows/$UUID/instances/$INSTANCE_UUID/messages"
curl -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
