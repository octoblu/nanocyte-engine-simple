#!/bin/bash

DATA='{"devices": ["b718ee1a-6d84-41aa-a62e-c5c9c98c9a68"], "topic": "button", "payload": {"from": "31f4bec0-5b2c-11e5-a712-9738e5b9aab2", "foo": "bar"}}'
URL='http://localhost:5050/flows/b718ee1a-6d84-41aa-a62e-c5c9c98c9a68/messages'
curl -X POST -H 'Content-Type: application/json' -d "$DATA" "$URL"
