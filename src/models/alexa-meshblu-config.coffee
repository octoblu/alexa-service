_ = require 'lodash'

class AlexaMeshbluConfig
  constructor: ({ meshbluConfig, request }) ->
    { accessToken } = request.sessionDetails ? {}
    try
      { uuid, token } = @_parseAccessToken accessToken
    catch
      return
    return unless uuid?
    return unless token?
    @_meshbluConfig = _.cloneDeep meshbluConfig
    @_meshbluConfig.uuid = uuid
    @_meshbluConfig.token = token

  get: =>
    return @_meshbluConfig

  _parseAccessToken: (accessToken) =>
    parsedToken = new Buffer(accessToken, 'base64').toString('utf8')
    [ uuid, token ] = parsedToken.split ':'
    return { uuid, token }

module.exports = AlexaMeshbluConfig
