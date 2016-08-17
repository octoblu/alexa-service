AuthenticatedHandler = require '../authenticated-handler'
EchoInService        = require '../../services/echo-in-service'

OPEN_MESSAGE="This skill allows you to trigger an Octoblu flow that perform a series of events or actions"

class HandleLaunchRequest
  constructor: ({ meshbluConfig, request, @response }) ->
    @echoInService = new EchoInService { meshbluConfig }
    @authenticatedHandler = new AuthenticatedHandler { meshbluConfig, request, @response }

  handle: (callback) =>
    @authenticatedHandler.handle callback, =>
      @echoInService.list (error, list) =>
        return callback error if error?
        @response.say "#{OPEN_MESSAGE}. Currently, #{list.toString()}"
        @response.shouldEndSession false, "Please say the name of a trigger associated with your account"
        callback null

module.exports = HandleLaunchRequest
