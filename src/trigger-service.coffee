uuid            = require 'node-uuid'
MeshbluHttp     = require 'meshblu-http'
MeshbluConfig   = require 'meshblu-config'
TriggerModel    = require './trigger-model'

class Triggers
  constructor: ->
    @triggerModel = new TriggerModel()

  trigger: (triggerId, flowId, requestId, params, callback=->) =>
    meshbluConfig = new MeshbluConfig {}
    meshbluHttp = new MeshbluHttp meshbluConfig.toJSON()

    message =
      devices: [flowId]
      topic: 'alexa-service'
      payload:
        from: triggerId
        params: params
        requestId: requestId
    meshbluConfig.message message, callback

  getTriggers: (callback=->) =>
    meshbluConfig = new MeshbluConfig {}
    meshbluHttp = new MeshbluHttp meshbluConfig.toJSON()
    meshbluHttp.devices type: 'octoblu:flow', (error, body) =>
      return callback 'unauthorized' if error?.message == 'unauthorized'
      return callback 'unable to get triggers' if error?

      triggers = @triggerModel.parseTriggersFromDevices body.devices
      callback null, triggers

  getMyTriggers: (callback=->) =>
    meshbluConfig = new MeshbluConfig {}
    meshbluHttp = new MeshbluHttp meshbluConfig.toJSON()

    meshbluHttp.devices type: 'octoblu:flow', owner: meshbluConfig.uuid, (error, body) =>
    return callback 'unauthorized' if error?.message == 'unauthorized'
    return callback 'unable to get triggers' if error?

    triggers = @triggerModel.parseTriggersFromDevices body.devices
    callback null, triggers

module.exports = Triggers
