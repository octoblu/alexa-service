AlexaModel      = require './alexa-model'
class Alexa
  constructor: ->
    @alexaModel = new AlexaModel

  debug: (request, response) =>
    @alexaModel.debug body: request.body, headers: request.headers, (error, alexaResponse) =>
      return response.status(500).end() if error?
      response.status(200).send alexaResponse

  trigger: (request, response) =>
    @alexaModel.trigger req.body, (error, alexaResponse) =>
      return response.status(500).end() if error?
      response.status(200).send alexaResponse
      
module.exports = Alexa
