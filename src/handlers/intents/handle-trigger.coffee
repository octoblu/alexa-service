EchoInService = require '../../services/echo-in-service'

class HandleTrigger
  constructor: ({ meshbluConfig, request, @response }) ->
    @echoInService = new EchoInService { meshbluConfig }

  handle: (callback) =>
    @echoInService.list (error, list) =>
      return callback error if error?
      @response.say list.toString()
      @response.shouldEndSession true
      callback null

module.exports = HandleTrigger
