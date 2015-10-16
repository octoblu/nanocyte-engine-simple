_         = require 'lodash'
Benchmark = require './benchmark'

count = _.last _.slice process.argv, 2
new Benchmark().runCount (count || 1), (error) =>
  console.error error if error?
  process.exit 0
