request         = require 'request'
Triggers        = require './trigger-service'

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
    return callback new Error "Invalid Intent" unless @INTENTS[intent.name]?
    @INTENTS[intent.name] alexaIntent, callback

  trigger: (alexaIntent, callback=->) =>
    {intent, requestId} = alexaIntent.request
    @triggers.getTriggers (error, triggers) =>
      return callback error if error?
      trigger = _.find triggers, name: intent?.slots?.Name?.value
      return callback new Error("No trigger by that name") unless trigger?
      @triggers.trigger trigger.id, trigger.flowId, requestId, alexaIntent, (error) =>
        return callback error if error?
        callback null

  respond: (request, callback=->) =>
    callback null, SUCCESS_RESPONSE

  open: (alexaIntent, callback=->) =>
    callback null, OPEN_RESPONSE

  close: (alexaIntent, callback=->) =>
    callback null, CLOSE_RESPONSE


module.exports = AlexaModel
