EchoInService        = require '../../services/echo-in-service'
AuthenticatedHandler = require '../authenticated-handler'
debug                = require('debug')('alexa-service:handle-list-triggers')

class HandleListTriggers
  constructor: ({ meshbluConfig, request, @response }) ->
    throw new Error 'Missing request' unless request?
    throw new Error 'Missing response' unless @response?

    @echoInService = new EchoInService { meshbluConfig }
    @authenticatedHandler = new AuthenticatedHandler { meshbluConfig, request, @response }

  handle: (callback) =>
    @authenticatedHandler.handle callback, =>
      @echoInService.list (error, list) =>
        debug 'got list of echo-ins', { error }
        return callback error if error?
        @response.say list.toString()
        @response.shouldEndSession true, "Please say the name of a trigger associated with your account"
        callback null

module.exports = HandleListTriggers
