MeshbluConfig   = require 'meshblu-config'
debug           = require('debug')('alexa-service:meshblu-config')
class NewMeshbluConfig extends MeshbluConfig
  constructor: (key) ->
    debug 'key', key
    super()
    @uuid_env_name = "#{key}_UUID"
    @token_env_name = "#{key}_TOKEN"
    @server_env_name = "#{key}_SERVER"
    @port_env_name = "#{key}_PORT"
    debug 'uuid_env_name', @uuid_env_name


module.exports = NewMeshbluConfig
