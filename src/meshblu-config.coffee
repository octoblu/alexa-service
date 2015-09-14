MeshbluConfig   = require 'meshblu-config'
debug           = require('debug')('alexa-service:meshblu-config')
class NewMeshbluConfig extends MeshbluConfig
  constructor: (key) ->
    debug 'key', key
    super()
    return if key == 'MESHBLU'
    @uuid_env_name = "UUID_#{key}"
    @token_env_name = "TOKEN_#{key}"
    @server_env_name = "SERVER_#{key}"
    @port_env_name = "PORT_#{key}"
    debug 'uuid_env_name', @uuid_env_name


module.exports = NewMeshbluConfig
