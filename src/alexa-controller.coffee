_               = require 'lodash'
AlexaModel      = require './alexa-model'
debug           = require('debug')('alexa-service:controller')

class Alexa
  constructor: ({@meshbluConfig,@restServiceUri}) ->
    @requestByType =
      'LaunchRequest': @open
      'IntentRequest': @intent
      'SessionEndedRequest': @close

  getMeshbluConfigFromRequest: (request) =>
    accessToken = request.body?.session?.user?.accessToken
    return unless accessToken?
    parsedToken = new Buffer(accessToken, 'base64').toString('utf8')
    [uuid, token] = parsedToken.split(':')
    meshbluConfig = _.clone @meshbluConfig
    meshbluConfig.uuid = uuid
    meshbluConfig.token = token
    return meshbluConfig

  getAlexaModel: (request) =>
    meshbluConfig = @meshbluConfig
    meshbluConfig = @getMeshbluConfigFromRequest request if request?
    alexaModel = new AlexaModel {meshbluConfig}
    return alexaModel

  debug: (request, response) =>
    debug 'debug reqeust', request.body
    @getAlexaModel(request).debug body: request.body, headers: request.headers, (error, alexaResponse) =>
      return response.status(500).end() if error?
      response.status(200).send alexaResponse

  trigger: (request, response) =>
    debug 'trigger request', request.body
    {type} = request.body?.request
    debug 'request type', type
    debug 'is a valid type', @requestByType[type]?
    return @requestByType[type] request, response if @requestByType[type]?
    alexaModel = @getAlexaModel request
    return response.status(200).send alexaModel.convertError new Error("Invalid Intent Type")

  intent: (request, response) =>
    {responseId} = request.body?.request
    debug 'intent', responseId
    alexaModel = @getAlexaModel request
    alexaModel.intent request.body, (error, result) =>
      debug 'responding', error: error
      return response.status(200).send alexaModel.convertError error if error?
      response.status(result.code).send result.data

  open: (request, response) =>
    debug 'opening session'
    alexaModel = @getAlexaModel request
    alexaModel.open request.body, (error, alexaResponse) =>
      debug 'responding', error: error, response: alexaResponse
      return response.status(200).send alexaModel.convertError error if error?
      return response.status(200).send alexaResponse

  close: (request, response) =>
    debug 'closing session'
    alexaModel = @getAlexaModel request
    alexaModel.close request.body, (error, alexaResponse) =>
      debug 'responding', error: error, response: alexaResponse
      return response.status(200).send alexaModel.convertError error if error?
      return response.status(200).send alexaResponse

  respond: (request, response) =>
    {responseId} = request.params
    return response.status(412).end() unless responseId?

    alexaModel = @getAlexaModel request
    alexaModel.respond responseId, request.body, (error, result) =>
      debug 'responding', error: error
      return response.status(500).send error: error if error?
      response.status(result.code).send result.data

  timeoutResponse: (value) =>
    {response, request} = value
    {responseId} = request.body?.request
    debug 'timeout response to', responseId
    response.status(200).send @getAlexaModel(request).convertError new Error "Flow unresponsive"

module.exports = Alexa
