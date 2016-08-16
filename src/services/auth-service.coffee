MeshbluHttp = require 'meshblu-http'

class AuthService
  constructor: ({ @meshbluConfig }) ->
    @meshblu = new MeshbluHttp @meshbluConfig

  validate: (callback) =>
    return callback null, false unless @meshbluConfig?
    @meshblu.authenticate (error) =>
      console.error 'Error:', error if error?
      return callback null, false if error?
      callback null, true

module.exports = AuthService
