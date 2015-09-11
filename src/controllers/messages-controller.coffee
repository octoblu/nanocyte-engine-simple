class MessagesController
  constructor: (options={}) ->
    {@inputHandler} = options
    @inputHandler ?= require '../handlers/input-handler'

  create: (req, res) =>
    @inputHandler.onMessage(req.body)
    res.status(201).end()

module.exports = MessagesController
