#!/bin/bash

# /flows//instances/

UUID=dd3d787a-7833-4581-9287-3ad2c5a1273a
INSTANCE_UUID=50d9c220-60ba-11e5-887f-c5b192523d1d

DATA='{"devices": ["dd3d787a-7833-4581-9287-3ad2c5a1273a"], "topic": "button", "payload": {"from": "a4023150-6077-11e5-bbea-bf7518d44b93", "foo": "bar", "bar": 2}}'
#URL="http://nanocyte-engine.octoblu.com/flows/$UUID/instances/$INSTANCE_UUID/messages"
URL="http://localhost:5050/flows/$UUID/instances/$INSTANCE_UUID/messages"
curl -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
