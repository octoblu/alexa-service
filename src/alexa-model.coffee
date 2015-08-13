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
    name = intent?.slots?.Name?.value
    @triggers.getTriggerByName name, (error, trigger) =>
      debug 'about to trigger'
      @triggers.trigger trigger.id, trigger.flowId, requestId, alexaIntent.request, (error) =>
        debug 'triggered', error
        return callback error if error?
        callback null

  respond: (body, callback=->) =>
    {responseText} = body ? {}
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
