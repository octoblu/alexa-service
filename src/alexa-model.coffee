_         = require 'lodash'
request   = require 'request'
responses = require './responses'
Rest      = require './rest-service'
debug     = require('debug')('alexa-service:model')

class AlexaModel
  constructor: ({@meshbluConfig,@restServiceUri}) ->
    @INTENTS =
      'Trigger': @trigger

  convertError: (error) =>
    response = _.clone responses.CLOSE_RESPONSE
    response.response.outputSpeech.text = error?.message ? error
    response

  debug: (json, callback=->) =>
    request.post 'http://requestb.in/1gy5wgo1', json: json, (error) =>
      return callback error if error?
      callback null, responses.DEBUG_RESPONSE

  intent: (alexaIntent, callback=->) =>
    {intent} = alexaIntent.request
    debug 'intent', intent
    return callback null, @convertError new Error("Invalid Intent") unless @INTENTS[intent.name]?
    debug 'intent name', intent.name
    @INTENTS[intent.name] alexaIntent, callback

  trigger: (alexaIntent, callback=->) =>
    debug 'triggering'
    {intent, responseId} = alexaIntent.request
    name = intent?.slots?.Name?.value
    rest = new Rest {@meshbluConfig,@restServiceUri}
    rest.trigger name, alexaIntent.request, (error, body) =>
      return callback error if error?
      callback null, body

  respond: (responseId, body, callback=->) =>
    rest = new Rest {@meshbluConfig,@restServiceUri}
    rest.respond responseId, body, callback

  open: (alexaIntent, callback=->) =>
    debug 'open'
    callback null, responses.OPEN_RESPONSE

  close: (alexaIntent, callback=->) =>
    debug 'close'
    callback null, responses.CLOSE_RESPONSE


module.exports = AlexaModel
