redis = require 'ioredis'
client = redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD, dropBufferSupport: true
module.exports = client
