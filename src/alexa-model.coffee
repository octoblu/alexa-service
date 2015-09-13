_               = require 'lodash'
request         = require 'request'
responses       = require './responses'
MeshbluConfig   = require './meshblu-config'
Triggers        = require './trigger-service'
debug           = require('debug')('alexa-service:model')

class AlexaModel
  constructor: ->
    @INTENTS =
      'Trigger': @trigger

  setAuthFromKey: (key) =>
    @meshbluConfig = new MeshbluConfig(key).toJSON()

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
    {intent, requestId} = alexaIntent.request
    name = intent?.slots?.Name?.value
    triggers = new Triggers @meshbluConfig
    triggers.getTriggerByName name, (error, trigger) =>
      return callback error  if error?
      debug 'about to trigger'
      triggers.trigger trigger.id, trigger.flowId, requestId, alexaIntent.request, (error) =>
        debug 'triggered', error
        return callback error if error?
        callback null

  respond: (body, callback=->) =>
    {responseText} = body ? {}
    debug 'respond', responseText
    response = _.clone responses.SUCCESS_RESPONSE
    response.response.outputSpeech.text = responseText if responseText
    callback null, response

  open: (alexaIntent, callback=->) =>
    debug 'open'
    callback null, responses.OPEN_RESPONSE

  close: (alexaIntent, callback=->) =>
    debug 'close'
    callback null, responses.CLOSE_RESPONSE


module.exports = AlexaModel
