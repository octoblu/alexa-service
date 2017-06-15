AlexaError     = require '../models/alexa-error'
SessionHandler = require '../handlers/session-handler'
TypeHandler    = require '../handlers/type-handler'
debug          = require('debug')('alexa-service:v2-controller')

class V2AlexaController
  constructor: ({ @timeoutSeconds, @meshbluConfig, @alexaServiceUri }) ->
    throw new Error 'Missing meshbluConfig' unless @meshbluConfig?
    throw new Error 'Missing alexaServiceUri' unless @alexaServiceUri?

  trigger: (req, res) =>
    debug 'trigger request', req.body
    sessionHandler = new SessionHandler { @timeoutSeconds, client: req.redisClient, @alexaServiceUri }
    sessionHandler.start req.body, (error, { request, response } = {}) =>
      return @handleError res, error if error?
      typeHandler = new TypeHandler {
        @meshbluConfig,
        @alexaServiceUri,
        request,
        response,
        sessionHandler
        version: 'v2'
      }
      typeHandler.handle (error) =>
        return @handleError res, error if error?
        sessionHandler.leave response.response, (error) =>
          return @handleError res, error if error?
          res.status(200).send response.response

  handleError: (res, error) =>
    return res.status(200).send error.response if error instanceof AlexaError
    res.sendError error

  respond: (req, res) =>
    { responseId, jobType } = req.body.metadata ? {}
    return res.sendStatus(422) unless responseId?
    return res.sendStatus(422) unless jobType?
    sessionHandler = new SessionHandler { @timeoutSeconds, client: req.redisClient, @alexaServiceUri }
    sessionHandler.respond { responseId, body: req.body }, (error) =>
      return res.sendError error if error?
      res.status(200).send { success: true }

module.exports = V2AlexaController
