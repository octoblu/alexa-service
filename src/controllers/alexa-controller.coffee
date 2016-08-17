_           = require 'lodash'
Alexa       = require 'alexa-app'
TypeHandler = require '../handlers/type-handler'
debug       = require('debug')('alexa-service:controller')

class AlexaController
  constructor: ({ @jobManager, @meshbluConfig, @alexaServiceUri }) ->
    throw new Error 'Missing meshbluConfig' unless @meshbluConfig?
    throw new Error 'Missing alexaServiceUri' unless @alexaServiceUri?
    throw new Error 'Missing jobManager' unless @jobManager?

  trigger: (req, res) =>
    debug 'trigger request', req.body
    { request, response } = @createRequestAndResponse req
    debug 'alexa request', request
    debug 'alexa response', response
    handler = new TypeHandler { @meshbluConfig, request, response }
    handler.handle (error) =>
      return @handleError res, response, error if error?
      res.status(200).send response.response

  createRequestAndResponse: (req) =>
    json = req.body
    json.session ?= {}
    json.session.user ?= {}
    json.session.application ?= {}
    request = new Alexa.request json
    response = new Alexa.response()
    _.each _.keys(request.sessionAttributes), (key) =>
      response.session key, request.sessionAttributes[key]
    return { request, response }

  handleError: (res, response, error) =>
    response.say error?.toString()
    response.shouldEndSession true
    return res.status(500).send response.response

  respond: (req, res) =>
    code = parseInt code if code?
    code ?= 200
    { responseId } = req.params
    message = {
      metadata: { code, responseId }
      data: req.body
    }
    @jobManager.createResponse 'response', message, (error) =>
      return res.sendError error if error?
      res.status(200).send { success: true }

module.exports = AlexaController
