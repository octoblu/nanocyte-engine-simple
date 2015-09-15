#!/usr/bin/env coffee

redis = require 'redis'
client = redis.createClient()


client.set "b718ee1a-6d84-41aa-a62e-c5c9c98c9a68/router/config", '{
  "31f4bec0-5b2c-11e5-a712-9738e5b9aab2": {
    "type": "nanocyte-node-trigger",
    "linkedTo": ["2ec047b0-5b2c-11e5-a712-9738e5b9aab2"]
  },
  "2ec047b0-5b2c-11e5-a712-9738e5b9aab2": {
    "type": "nanocyte-node-debug",
    "linkedTo": ["meshblu-output"]
  },
  "meshblu-output": {
    "type": "meshblu-output",
    "linkedTo": []
  }
}', redis.print

client.set "b718ee1a-6d84-41aa-a62e-c5c9c98c9a68/31f4bec0-5b2c-11e5-a712-9738e5b9aab2/config", "{}", redis.print
client.set "b718ee1a-6d84-41aa-a62e-c5c9c98c9a68/2ec047b0-5b2c-11e5-a712-9738e5b9aab2/config", "{}", redis.print
client.set "b718ee1a-6d84-41aa-a62e-c5c9c98c9a68/meshblu-output/config", '{
  "uuid": "b718ee1a-6d84-41aa-a62e-c5c9c98c9a68",
  "token": "8bd168cf76bf99273ae7e4d3c7c8db9ec68da0a1",
  "server": "meshblu.octoblu.com",
  "port": 443
}', redis.print
