_          = require 'lodash'
md5        = require 'md5'
AlexaModel = require './alexa-model'
debug      = require('debug')('alexa-service:controller')

class Alexa
  constructor: ->
    @pendingRequests = {}
    @requestByType =
      'LaunchRequest': @open
      'IntentRequest': @intent
      'SessionEndedRequest': @end

  getKeyFromRequest: (request) =>
    userId = md5 request.body?.session?.user?.userId
    envName = "#{userId}_UUID"
    debug 'user id (md5)', userId, process.env[envName]?
    return userId if process.env[envName]?
    return 'MESHBLU'

  debug: (request, response) =>
    debug 'debug reqeust', request.body
    alexaModel = new AlexaModel
    alexaModel.setAuthFromKey @getKeyFromRequest request
    alexaModel.debug body: request.body, headers: request.headers, (error, alexaResponse) =>
      return response.status(500).end() if error?
      response.status(200).send alexaResponse

  trigger: (request, response) =>
    debug 'trigger request', request.body
    {type} = request.body?.request
    debug 'request type', type
    return response.status(412).end() unless @requestByType[type]?
    debug 'is a valid type'
    @requestByType[type] request, response

  intent: (request, response) =>
    {requestId} = request.body?.request
    debug 'intent', requestId
    @pendingRequests[requestId] = request: request, response: response
    debug 'stored pending request'
    alexaModel = new AlexaModel
    alexaModel.setAuthFromKey @getKeyFromRequest request
    alexaModel.intent request.body, (error) =>
      debug 'responding', error: error
      return response.status(200).send alexaModel.convertError error if error?
      debug 'leaving open'

  open: (request, response) =>
    debug 'opening session'
    alexaModel = new AlexaModel
    alexaModel.setAuthFromKey @getKeyFromRequest request
    alexaModel.open request.body, (error, alexaResponse) =>
      debug 'responding', error: error, response: alexaResponse
      return response.status(500).end() if error?
      return response.status(200).send alexaResponse

  close: (request, response) =>
    debug 'closing session'
    alexaModel = new AlexaModel
    alexaModel.setAuthFromKey @getKeyFromRequest request
    alexaModel.close request.body, (error, alexaResponse) =>
      debug 'responding', error: error, response: alexaResponse
      return response.status(500).end() if error?
      return response.status(200).send alexaResponse

  respond: (request, response) =>
    requestId = request.body.requestId
    debug 'responding to request', requestId
    return response.status(412).end() unless requestId?
    return response.status(404).end() unless @pendingRequests[requestId]?
    alexaModel = new AlexaModel
    alexaModel.setAuthFromKey @getKeyFromRequest request
    alexaModel.respond request.body, (error, alexaResponse) =>
      debug 'responded to request', error, alexaResponse
      pendingResponse = @pendingRequests[requestId]?.response
      delete @pendingRequests[requestId]
      return pendingResponse.status(200).send alexaModel.convertError error if error?
      pendingResponse.status(200).send alexaResponse
      response.status(200).send success: true

module.exports = Alexa
