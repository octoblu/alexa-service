_           = require 'lodash'
responses   = require './responses'
RestService = require '../services/rest-service'
debug       = require('debug')('alexa-service:model')

class AlexaModel
  constructor: ({@meshbluConfig,@restServiceUri}) ->
    @INTENTS =
      'Trigger': @trigger

  convertError: (error) =>
    response = _.clone responses.CLOSE_RESPONSE
    response.response.outputSpeech.text = error?.message ? error
    response

  intent: (alexaIntent, callback=->) =>
    {intent} = alexaIntent.request
    debug 'intent', intent
    return callback null, @convertError new Error("Invalid Intent") unless @INTENTS[intent.name]?
    debug 'intent name', intent.name
    @INTENTS[intent.name] alexaIntent, callback

  trigger: (alexaIntent, callback=->) =>
    debug 'triggering a trigger'
    {intent, responseId} = alexaIntent.request
    name = intent?.slots?.Name?.value
    restService = new RestService {@meshbluConfig,@restServiceUri}
    restService.trigger name, alexaIntent.request, (error, body) =>
      return callback error if error?
      callback null, body

  respond: (responseId, body, callback=->) =>
    debug 'responding', responseId
    restService = new RestService {@meshbluConfig,@restServiceUri}
    restService.respond responseId, body, callback

  open: (alexaIntent, callback=->) =>
    debug 'open'
    callback null, responses.OPEN_RESPONSE

  close: (alexaIntent, callback=->) =>
    debug 'close'
    callback null, responses.CLOSE_RESPONSE

module.exports = AlexaModel
