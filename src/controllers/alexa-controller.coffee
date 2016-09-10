_              = require 'lodash'
SessionHandler = require '../handlers/session-handler'
TypeHandler    = require '../handlers/type-handler'
debug          = require('debug')('alexa-service:controller')

class AlexaController
  constructor: ({ @timeoutSeconds, @meshbluConfig, @alexaServiceUri }) ->
    throw new Error 'Missing meshbluConfig' unless @meshbluConfig?
    throw new Error 'Missing alexaServiceUri' unless @alexaServiceUri?

  trigger: (req, res) =>
    debug 'trigger request', req.body
    sessionHandler = new SessionHandler { @timeoutSeconds, client: req.redisClient }
    sessionHandler.start req.body, (error, { request, response } = {}) =>
      return res.sendError error if error?
      typeHandler = new TypeHandler {
        @meshbluConfig,
        @alexaServiceUri,
        request,
        response,
        sessionHandler
      }
      typeHandler.handle (error) =>
        return res.sendError error if error?
        sessionHandler.leave response.response, (error) =>
          return res.sendError error if error?
          res.status(200).send response.response

  respond: (req, res) =>
    { responseId } = req.params
    response       = req.body
    sessionHandler = new SessionHandler { @timeoutSeconds, client: req.redisClient }
    sessionHandler.respond { responseId, response }, (error) =>
      return res.sendError error if error?
      res.status(200).send { success: true }

module.exports = AlexaController
