AlexaModel      = require './alexa-model'
debug           = require('debug')('alexa-service:controller')

class Alexa
  constructor: ->
    @alexaModel = new AlexaModel
    @pendingRequests = {}
    @requestByType =
      'LaunchRequest': @open
      'IntentRequest': @intent
      'SessionEndedRequest': @end

  debug: (request, response) =>
    debug 'debug reqeust', request.body
    @alexaModel.debug body: request.body, headers: request.headers, (error, alexaResponse) =>
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
    @alexaModel.intent request.body, (error) =>
      debug 'responding', error
      return response.status(500).end() if error?
      debug 'leaving open'

  open: (request, response) =>
    debug 'opening session'
    @alexaModel.open request.body, (error, alexaResponse) =>
      debug 'responding', error, alexaResponse
      return response.status(500).end() if error?
      return response.status(200).send alexaResponse

  close: (request, response) =>
    debug 'closing session'
    @alexaModel.close request.body, (error, alexaResponse) =>
      debug 'responding', error, alexaResponse
      return response.status(500).end() if error?
      return response.status(200).send alexaResponse

  respond: (request, response) =>
    requestId = request.body.requestId
    return response.status(412).end() unless requestId?
    return response.status(404).end() unless @pendingRequests[requestId]?
    @alexaModel.respond request.body, (error, alexaResponse) =>
      return response.status(500).end() if error?
      pendingResponse = @pendingRequests[requestId]?.request
      pendingResponse.status(200).send alexaResponse

module.exports = Alexa
