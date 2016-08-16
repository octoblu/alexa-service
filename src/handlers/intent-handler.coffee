_       = require 'lodash'
Intents = require './intents'

class IntentHandler
  constructor: ({ meshbluConfig, request, @response }) ->
    @intentName = _.get request, 'request.intent.name'
    @options = { meshbluConfig, request, @response }

  handle: (callback) =>
    return @_invalidIntent callback unless Intents[@intentName]?
    @intent = new Intents[@intentName] @options
    @intent.handle callback

  _invalidIntent: (callback) =>
    message = "Sorry, the application didn't know what to do with that intent."
    @response.say message
    @response.shouldEndSession true, "Please say the name of a trigger associated with your account"
    callback null

module.exports = IntentHandler
