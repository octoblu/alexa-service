_     = require 'lodash'
debug = require('debug')('alexa-service:alexa-meshblu-config')

class AlexaMeshbluConfig
  constructor: ({ meshbluConfig, request }) ->
    { accessToken } = request.sessionDetails ? {}
    @_originalMeshbluConfig = meshbluConfig
    debug 'got access token', accessToken
    @createNewConfig accessToken

  createNewConfig: (accessToken) =>
    { uuid, token } = @_parseAccessToken accessToken
    return unless uuid? || token?
    @_meshbluConfig = _.cloneDeep @_originalMeshbluConfig
    if @_meshbluConfig.server?
      @_meshbluConfig.hostname = @_meshbluConfig.server
      delete @_meshbluConfig.server
    @_meshbluConfig.uuid = uuid
    @_meshbluConfig.token = token

  get: =>
    return @_meshbluConfig

  _parseAccessToken: (accessToken) =>
    try
      parsedToken = new Buffer(accessToken, 'base64').toString('utf8')
      [ uuid, token ] = parsedToken.split ':'
    catch error
      debug "Error parsing access token:", { message: error.message, accessToken }
      return {}

    return { uuid, token }

module.exports = AlexaMeshbluConfig
