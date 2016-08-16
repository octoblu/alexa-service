AuthService = require '../../services/auth-service'
EchoInService = require '../../services/echo-in-service'

OPEN_MESSAGE="This skill allows you to trigger an Octoblu flow that perform a series of events or actions"

class HandleLaunchRequest
  constructor: ({ meshbluConfig, @request, @response }) ->
    @echoInService = new EchoInService { meshbluConfig }
    @authService = new AuthService { meshbluConfig }

  handle: (callback) =>
    @authService.validate (error, valid) =>
      return callback error if error?
      return @_handleInvalidAuth callback unless valid
      @_handleValidAuth callback

  _handleValidAuth: (callback) =>
    @echoInService.list (error, list) =>
      return callback error if error?
      @response.say "#{OPEN_MESSAGE}. Currently, #{list.toString()}"
      @response.shouldEndSession true
      callback null

  _handleInvalidAuth: (callback) =>
    @response.say "Please go to your Alexa app and link your account."
    @response.linkAccount()
    callback null

module.exports = HandleLaunchRequest
