_           = require 'lodash'
Alexa       = require 'alexa-app'
TypeHandler = require '../handlers/type-handler'
debug       = require('debug')('alexa-service:controller')

class AlexaController
  constructor: ({ @meshbluConfig }) ->
    throw new Error 'Missing meshbluConfig argument' unless @meshbluConfig?

  trigger: (req, res) =>
    debug 'trigger request', req.body
    { request, response } = @createRequestAndResponse req
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
    res.sendStatus 204

module.exports = AlexaController
