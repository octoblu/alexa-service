uuid            = require 'node-uuid'
MeshbluHttp     = require 'meshblu-http'
MeshbluConfig   = require 'meshblu-config'
TriggerModel    = require './trigger-model'
debug           = require('debug')('alexa-service:triggers-service')

class Triggers
  constructor: ->
    @triggerModel = new TriggerModel()

  trigger: (triggerId, flowId, requestId, params, callback=->) =>
    debug 'trigger trigger'
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
    debug 'getting triggers'
    meshbluConfig = new MeshbluConfig {}
    meshbluHttp = new MeshbluHttp meshbluConfig.toJSON()
    meshbluHttp.devices type: 'octoblu:flow', (error, body) =>
      return callback 'unauthorized' if error?.message == 'unauthorized'
      return callback 'unable to get triggers' if error?

      triggers = @triggerModel.parseTriggersFromDevices body.devices
      callback null, triggers

  getMyTriggers: (callback=->) =>
    debug 'getting my triggers'
    meshbluConfig = new MeshbluConfig {}
    meshbluHttp = new MeshbluHttp meshbluConfig.toJSON()

    meshbluHttp.devices {type: 'octoblu:flow', owner: meshbluConfig.uuid}, (error, body) =>
      return callback 'unauthorized' if error?.message == 'unauthorized'
      return callback 'unable to get triggers' if error?

      triggers = @triggerModel.parseTriggersFromDevices body.devices
      callback null, triggers

  getTriggerByName: (name, callback=->) =>
    debug 'get triggers by name', name
    @getMyTriggers (error, triggers) =>
      debug 'got triggers', error, _.size(triggers), _.pluck(triggers, 'name')
      return callback error if error?
      debug 'searching for name', name
      trigger = _.find triggers, name: name
      debug 'trigger', trigger
      return callback new Error("No trigger by that name") unless trigger?
      callback null, trigger

module.exports = Triggers
