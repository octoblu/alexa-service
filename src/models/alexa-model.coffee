_           = require 'lodash'
responses   = require './responses'
RestService = require '../services/rest-service'
MeshbluHttp = require 'meshblu-http'
Triggers    = require 'triggers-service'
debug       = require('debug')('alexa-service:model')

class AlexaModel
  constructor: ({@meshbluConfig,@restServiceUri}) ->
    @INTENTS =
      'Trigger': @trigger
      'ListTriggers': @listTriggers
      'AMAZON.HelpIntent': @help
      'AMAZON.StopIntent': @close

  convertError: (error) =>
    return error if error?.response?.outputSpeech?
    response = _.cloneDeep responses.CLOSE_RESPONSE
    response.response.outputSpeech.text = error?.message ? error
    response

  convertResponse: ({responseText, closeSession}) =>
    response = _.cloneDeep responses.SUCCESS_RESPONSE
    response.response.outputSpeech.text = responseText if responseText?
    response.response.shouldEndSession = false if closeSession
    response

  unauthorizedResponse: =>
    return _.cloneDeep responses.LINK_ACCOUNT_CARD_RESPONSE

  validateConfig: (callback) =>
    return callback @unauthorizedResponse() unless @meshbluConfig?
    meshbluConfig = _.cloneDeep @meshbluConfig
    if meshbluConfig.server?
      meshbluConfig.hostname = meshbluConfig.server
      delete meshbluConfig.server
    meshbluHttp = new MeshbluHttp meshbluConfig
    meshbluHttp.authenticate callback

  intent: (alexaIntent, callback) =>
    {intent} = alexaIntent.request
    debug 'intent', intent
    return @invalidIntent callback unless @INTENTS[intent.name]?
    debug 'running intent...'
    @INTENTS[intent.name] alexaIntent, callback

  trigger: (alexaIntent, callback) =>
    debug 'triggering a trigger'
    {intent} = alexaIntent.request
    name = intent?.slots?.Name?.value
    @validateConfig (error) =>
      return callback @unauthorizedResponse() if error?.code == 403
      return callback error if error?
      restService = new RestService {@meshbluConfig,@restServiceUri}
      restService.trigger name, alexaIntent.request, (error, result) =>
        return callback error if error?
        return callback result.data?.error ? result.data if result.code > 299
        callback null, @convertResponse result.data

  listTriggers: ({}, callback) =>
    debug 'listing triggers'
    @validateConfig (error) =>
      debug 'valid config', { error }
      return callback error if error?
      triggers = new Triggers {@meshbluConfig}
      triggers.myTriggers {type: 'operation:echo-in'}, (error, triggers) =>
        return callback error if error?
        triggersList = _.map(triggers, 'name')
        responseText = "You don't have any echo-in triggers. Get started by importing one or more alexa bluprints."
        responseText = "Your triggers are #{triggersList.join(', and ')}. Say a trigger name to perform the action" if _.size triggersList
        callback null, @convertResponse {responseText}

  respond: (responseId, body, callback) =>
    debug 'responding', responseId
    restService = new RestService {@meshbluConfig,@restServiceUri}
    restService.respond responseId, body, callback

  open: ({}, callback) =>
    debug 'open'
    @listTriggers {}, (error, response) =>
      return callback error if error?
      _responseText = response.response.outputSpeech.text
      responseText = "This skill allows you to trigger an Octoblu flow that perform a series of events or actions. Currently, #{_responseText}"
      callback null, @convertResponse {responseText, closeSession: true}

  help: ({}, callback) =>
    debug 'help'
    responseText = "Tell Alexa to trigger a flow by saying the name of your Echo in thing. If you are experiencing problems, make sure that your Octoblu account is properly linked and that you have your triggers named properly"
    callback null, @convertResponse {responseText, closeSession: true}

  invalidIntent: (callback) =>
    debug 'invalid intent'
    @open {}, (error, response) =>
      return callback error if error?
      _responseText = response.response.outputSpeech.text
      responseText = "I don't understand this action. #{_responseText}"
      callback null, @convertResponse {responseText}

  close: (alexaIntent, callback) =>
    debug 'close'
    callback null, responses.CLOSE_RESPONSE

module.exports = AlexaModel
