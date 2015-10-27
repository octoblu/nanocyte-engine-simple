redis = require 'redis'
client = redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD
client.unref()
module.exports = client
