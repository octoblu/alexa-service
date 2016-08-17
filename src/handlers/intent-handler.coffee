_       = require 'lodash'
debug   = require('debug')('alexa-service:intent-handler')
Intents = require './intents'

class IntentHandler
  constructor: ({ meshbluConfig, request, @response }) ->
    @intentName = _.get request, 'data.request.intent.name'
    debug 'received intent', { @intentName }
    @options = { meshbluConfig, request, @response }

  handle: (callback) =>
    return @_invalidIntent callback unless Intents[@intentName]?
    @intent = new Intents[@intentName] @options
    @intent.handle callback

  _invalidIntent: (callback) =>
    console.error "invalid intent: #{@intentName}"
    message = "Sorry, the application didn't know what to do with that intent."
    @response.say message
    @response.shouldEndSession true, "Please say the name of a trigger associated with your account"
    callback null

module.exports = IntentHandler
