AlexaModel      = require './alexa-model'
class Alexa
  constructor: ->
    @alexaModel = new AlexaModel
    @pendingRequests = {}
    @requestByType =
      'LaunchRequest': @open
      'IntentRequest': @intent
      'SessionEndedRequest': @end

  debug: (request, response) =>
    @alexaModel.debug body: request.body, headers: request.headers, (error, alexaResponse) =>
      return response.status(500).end() if error?
      response.status(200).send alexaResponse

  trigger: (request, response) =>
    {type} = request.body?.request
    return response.status(412).end() unless @requestByType[type]?
    @requestByType[type] request, response

  intent: (request, response) =>
    {requestId} = request.body?.request
    @pendingRequests[requestId] = request: request, response: response
    @alexaModel.trigger request.body, (error) =>
      return response.status(500).end() if error?

  open: (request, repsonse) =>
    @alexaModel.open request.body, (error, alexaResponse) =>
      return response.status(500).end() if error?
      return response.status(200).send alexaResponse

  close: (request, repsonse) =>
    @alexaModel.close request.body, (error, alexaResponse) =>
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
