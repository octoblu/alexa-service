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
      'Amazon.HelpIntent': @listTriggers

  convertError: (error) =>
    response = _.cloneDeep responses.CLOSE_RESPONSE
    response.response.outputSpeech.text = error?.message ? error
    response

  convertResponse: ({responseText, closeSession}) =>
    response = _.cloneDeep responses.SUCCESS_RESPONSE
    response.response.outputSpeech.text = responseText if responseText?
    response.response.shouldEndSession = false if closeSession
    response

  validateConfig: (callback)=>
    return callback new Error 'Unauthorized' unless @meshbluConfig?
    meshbluHttp = new MeshbluHttp @meshbluConfig
    meshbluHttp.whoami callback

  intent: (alexaIntent, callback) =>
    {intent} = alexaIntent.request
    debug 'intent', intent
    return @invalidIntent callback unless @INTENTS[intent.name]?
    debug 'intent name', intent.name
    @INTENTS[intent.name] alexaIntent, callback

  trigger: (alexaIntent, callback) =>
    debug 'triggering a trigger'
    {intent} = alexaIntent.request
    name = intent?.slots?.Name?.value
    @validateConfig (error) =>
      return callback error if error?
      restService = new RestService {@meshbluConfig,@restServiceUri}
      restService.trigger name, alexaIntent.request, (error, result) =>
        return callback error if error?
        return callback result.data?.error ? result.data if result.code > 299
        callback null, @convertResponse result.data

  listTriggers: ({}, callback) =>
    debug 'triggering a trigger'
    @validateConfig (error) =>
      return callback error if error?
      triggers = new Triggers {@meshbluConfig}
      triggers.myTriggers {type: 'operation:echo-in'}, (error, triggers) =>
        return callback error if error?
        triggersList = _.map(triggers, 'name')
        responseText = "You don't have any echo-in triggers. Get started by importing one or more alexa bluprints."
        responseText = "Your triggers are #{triggersList.join(', and ')}" if _.size triggersList
        callback null, @convertResponse {responseText}

  respond: (responseId, body, callback) =>
    debug 'responding', responseId
    restService = new RestService {@meshbluConfig,@restServiceUri}
    restService.respond responseId, body, callback

  open: ({}, callback) =>
    debug 'open'
    @listTriggers {}, (error, response) =>
      _responseText = response.response.outputSpeech.text
      responseText = "This skill allows you to trigger an Octoblu flow that perform a series of events or actions. Currently, #{_responseText}"
      callback null, @convertResponse {responseText, closeSession: true}

  invalidIntent: (callback) =>
    debug 'open'
    @open {}, (error, response) =>
      _responseText = response.response.outputSpeech.text
      responseText = "I don't understand this action. #{_responseText}"
      callback null, @convertResponse {responseText}

  close: (alexaIntent, callback) =>
    debug 'close'
    callback null, responses.CLOSE_RESPONSE

module.exports = AlexaModel
