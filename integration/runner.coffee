_         = require 'lodash'
Benchmark = require './benchmark'


count = parseInt(process.argv[2])
maxAllowedTime = parseInt(process.argv[3])

count ?= 1
maxAllowedTime ?= 100

new Benchmark().runCount count: count, maxAllowedTime: maxAllowedTime, (error) =>
  console.error error if error?
  process.exit 0
