MeshbluHttp = require 'meshblu-http'
EchoDevice  = require '../models/echo-device'
debug       = require('debug')('alexa-service:echo-in-service')

class EchoDeviceService
  constructor: ({ meshbluConfig }) ->
    @meshblu = new MeshbluHttp meshbluConfig

  get: (callback) =>
    @meshblu.whoami (error, device) =>
      return callback error if error?
      echoDevice = new EchoDevice
      echoDevice.fromJSON device
      callback null, echoDevice 

  message: (message, callback) =>
    debug 'messaging', message
    @meshblu.message message, callback

module.exports = EchoDeviceService
