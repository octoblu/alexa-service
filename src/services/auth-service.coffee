MeshbluHttp = require 'meshblu-http'
debug       = require('debug')('alexa-service:auth-service')

class AuthService
  constructor: ({ @meshbluConfig }) ->
    @meshblu = new MeshbluHttp @meshbluConfig

  validate: (callback) =>
    return callback null, false unless @meshbluConfig?
    @meshblu.authenticate (error, result) =>
      debug 'auth validation', { error, result }
      console.error 'Error:', error if error?
      return callback null, false if error?
      callback null, true

module.exports = AuthService
