request         = require 'request'
Triggers        = require './trigger-service'
debug           = require('debug')('alexa-service:model')
_               = require 'lodash'

DEBUG_RESPONSE  = {
  "version": "1.0",
  "response": {
    "outputSpeech": {
      "type": "PlainText",
      "text": "It has been done!"
    },
    "shouldEndSession": true
  }
}

OPEN_RESPONSE  = {
  "version": "1.0",
  "response": {
    "outputSpeech": {
      "type": "PlainText",
      "text": "What would you like to do?"
    },
    "shouldEndSession": false
  }
}

CLOSE_RESPONSE  = {
  "version": "1.0",
  "response": {
    "outputSpeech": {
      "type": "PlainText",
      "text": "Session Closed"
    },
    "shouldEndSession": true
  }
}

SUCCESS_RESPONSE  = {
  "version": "1.0",
  "response": {
    "outputSpeech": {
      "type": "PlainText",
      "text": "Successful request"
    },
    "shouldEndSession": false
  }
}

class AlexaModel
  constructor: ->
    @triggers = new Triggers
    @INTENTS =
      'Trigger': @trigger

  debug: (json, callback=->) =>
    request.post 'http://requestb.in/1gy5wgo1', json: json, (error) =>
      return callback error if error?
      callback null, DEBUG_RESPONSE

  intent: (alexaIntent, callback=->) =>
    {intent} = alexaIntent.request
    debug 'intent', intent
    return callback new Error "Invalid Intent" unless @INTENTS[intent.name]?
    debug 'intent name', intent.name
    @INTENTS[intent.name] alexaIntent, callback

  trigger: (alexaIntent, callback=->) =>
    debug 'triggering'
    {intent, requestId} = alexaIntent.request
    @triggers.getTriggers (error, triggers) =>
      debug 'got triggers', error, triggers
      return callback error if error?
      name = intent?.slots?.Name?.value
      trigger = _.find triggers, name: name
      debug 'trigger', name: name, trigger: trigger
      return callback new Error("No trigger by that name") unless trigger?
      @triggers.trigger trigger.id, trigger.flowId, requestId, alexaIntent, (error) =>
        debug 'triggered', error
        return callback error if error?
        callback null

  respond: (request, callback=->) =>
    {responseText} = request.body
    debug 'respond', responseText
    response = _.clone SUCCESS_RESPONSE
    response.response.outputSpeech.text = responseText if responseText
    callback null, response

  open: (alexaIntent, callback=->) =>
    debug 'open'
    callback null, OPEN_RESPONSE

  close: (alexaIntent, callback=->) =>
    debug 'close'
    callback null, CLOSE_RESPONSE


module.exports = AlexaModel
