Redis = require 'ioredis'
client = new Redis process.env.REDIS_URI, dropBufferSupport: true
module.exports = client
