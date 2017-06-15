MeshbluHttp = require 'meshblu-http'
EchoDevice  = require '../models/echo-device'
debug       = require('debug')('alexa-service:echo-in-service')

class EchoDeviceService
  constructor: ({ meshbluConfig, @alexaServiceUri }) ->
    throw new Error 'EchoDeviceService: requires meshbluConfig' unless meshbluConfig?
    throw new Error 'EchoDeviceService: requires alexaServiceUri' unless @alexaServiceUri?
    @meshbluHttp = new MeshbluHttp meshbluConfig

  create: (callback) =>
    @meshbluHttp.register {type: 'alexa:echo-device'}, callback
    
  get: (callback) =>
    @meshbluHttp.whoami (error, device) =>
      return callback error if error?
      echoDevice = new EchoDevice { @alexaServiceUri }
      echoDevice.fromJSON device
      callback null, echoDevice

  message: (message, callback) =>
    debug 'messaging', message
    @meshbluHttp.message message, callback

  update: (uuid, properties, callback) =>
    debug 'update', { uuid, properties }
    @meshbluHttp.updateDangerously uuid, properties, callback

module.exports = EchoDeviceService
