AuthService   = require '../services/auth-service'
debug         = require('debug')('alexa-service:authenticated-handler')

class AuthenticatedHandler
  constructor: ({ meshbluConfig, request, @response }) ->
    throw new Error 'Missing meshbluConfig' unless meshbluConfig?
    throw new Error 'Missing request' unless request?
    throw new Error 'Missing response' unless @response?
    @authService  = new AuthService { meshbluConfig, request }

  handle: (callback, next) =>
    @authService.validate (error, valid) =>
      return callback error if error?
      return @_handleInvalidAuth callback unless valid
      next null

  _handleInvalidAuth: (callback) =>
    @response.say "Please go to your Alexa app and link your account."
    @response.linkAccount()
    callback null

module.exports = AuthenticatedHandler
