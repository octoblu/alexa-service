_          = require 'lodash'
md5        = require 'md5'
AlexaModel = require './alexa-model'
PendingRequests = require './pending-requests'
debug      = require('debug')('alexa-service:controller')

class Alexa
  constructor: ->
    @pendingRequests = new PendingRequests
    @requestByType =
      'LaunchRequest': @open
      'IntentRequest': @intent
      'SessionEndedRequest': @close

  getKeyFromRequest: (request) =>
    userId = md5 request.body?.session?.user?.userId
    envName = "UUID_#{userId}"
    debug 'user id (md5)', userId, process.env[envName]?
    return userId if process.env[envName]?
    return 'MESHBLU'

  getAlexaModel: (request) =>
    alexaModel = new AlexaModel
    alexaModel.setAuthFromKey @getKeyFromRequest request if request?
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
    {requestId} = request.body?.request
    debug 'intent', requestId
    value = request: request, response: response
    @pendingRequests.set requestId, value, @timeoutResponse
    debug 'stored pending request'
    alexaModel = @getAlexaModel request
    alexaModel.intent request.body, (error) =>
      debug 'responding', error: error
      return response.status(200).send alexaModel.convertError error if error?
      debug 'leaving open'

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
    requestId = request.body.requestId
    pendingValue = @pendingRequests.get requestId
    debug 'responding to request', requestId
    return response.status(412).end() unless requestId?
    return response.status(404).end() unless pendingValue?

    pendingResponse = pendingValue.response
    @pendingRequests.remove requestId

    alexaModel = @getAlexaModel request
    alexaModel.respond request.body, (error, alexaResponse) =>
      debug 'responding', error: error, response: alexaResponse
      return pendingResponse.status(200).send alexaModel.convertError error if error?
      pendingResponse.status(200).send alexaResponse
      response.status(200).send alexaResponse

  timeoutResponse: (value) =>
    {response, request} = value
    {requestId} = request.body?.request
    debug 'timeout response to', requestId
    response.status(200).send @getAlexaModel(request).convertError new Error "Flow unresponsive"

module.exports = Alexa
