#!/bin/bash

# /flows//instances/

UUID=dd3d787a-7833-4581-9287-3ad2c5a1273a
INSTANCE_UUID=76e53320-60a9-11e5-9795-07a21d27e0d2

DATA='{"devices": ["dd3d787a-7833-4581-9287-3ad2c5a1273a"], "topic": "button", "payload": {"from": "a4023150-6077-11e5-bbea-bf7518d44b93", "foo": "bar"}}'
#URL="http://nanocyte-engine.octoblu.com/flows/$UUID/instances/$INSTANCE_UUID/messages"
URL="http://localhost:5050/flows/$UUID/instances/$INSTANCE_UUID/messages"
curl -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
