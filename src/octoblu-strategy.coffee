_               = require 'lodash'
passport        = require 'passport'
PassportOctoblu = require 'passport-octoblu'
MeshbluHttp     = require 'meshblu-http'
debug           = require('debug')('octoblu-demo-service:octoblu-strategy')

class OctobluStrategy
  constructor: ({ @meshbluConfig, @oauthCallbackUrl }) ->
    throw new Error 'OctobluStrategy: requires @meshbluConfig' unless @meshbluConfig?
    throw new Error 'OctobluStrategy: requires @oauthCallbackUrl' unless @oauthCallbackUrl?

  use: =>
    passport.use new PassportOctoblu {
      clientID:          @meshbluConfig.uuid
      clientSecret:      @meshbluConfig.token
      meshbluConfig:     _.cloneDeep @meshbluConfig
      callbackUrl:       @oauthCallbackUrl
      passReqToCallback: true
    }, (request, bearerToken, secret, profile, next) =>
      debug 'authenticated', { bearerToken, secret }
      { uuid, token } = @_parseBearerToken bearerToken
      @_generateMeshbluAuth { uuid, token }, (error, meshbluAuth) =>
        return next(error) if error?
        request.meshbluAuth = meshbluAuth
        next null, meshbluAuth

  _generateMeshbluAuth: ({ uuid, token }, callback) =>
    meshbluHttp = new MeshbluHttp @_generateNewConfig { uuid, token }
    meshbluHttp.generateAndStoreToken uuid, (error, result) =>
      return callback error if error?
      callback null, @_generateNewConfig result

  _generateNewConfig: ({ uuid, token }) =>
    meshbluAuth = _.cloneDeep @meshbluConfig
    meshbluAuth.uuid = uuid
    meshbluAuth.token = token
    return meshbluAuth

  _parseBearerToken: (bearerToken) =>
    decoded = new Buffer(bearerToken, 'base64').toString('utf8')
    [uuid,token] = decoded?.split(':') ? []
    return { uuid, token }

module.exports = OctobluStrategy
