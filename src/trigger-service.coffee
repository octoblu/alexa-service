uuid            = require 'node-uuid'
MeshbluHttp     = require 'meshblu-http'
MeshbluConfig   = require 'meshblu-config'
TriggerModel    = require './trigger-model'
debug           = require('debug')('alexa-service:triggers-service')
_               = require 'lodash'
class Triggers
  constructor: ->
    @triggerModel = new TriggerModel()

  trigger: (triggerId, flowId, requestId, params, callback=->) =>
    debug 'trigger trigger'
    meshbluConfig = new MeshbluConfig {}
    meshbluHttp = new MeshbluHttp meshbluConfig.toJSON()

    message =
      devices: [flowId]
      topic: 'triggers-service'
      payload:
        from: triggerId
        params: params
        requestId: requestId
    debug 'trigger message', message
    meshbluHttp.message message, callback

  getTriggers: (query={}, callback=->) =>
    debug 'getting triggers'
    meshbluConfig = new MeshbluConfig {}
    meshbluHttp = new MeshbluHttp meshbluConfig.toJSON()
    query.type ?= 'octoblu:flow'
    meshbluHttp.devices query, (error, body) =>
      return callback 'unauthorized' if error?.message == 'unauthorized'
      return callback 'unable to get triggers' if error?

      triggers = @triggerModel.parseTriggersFromDevices body.devices
      callback null, triggers

  getMyTriggers: (query={}, callback=->) =>
    debug 'getting my triggers', query
    meshbluConfig = new MeshbluConfig {}
    meshbluHttp = new MeshbluHttp meshbluConfig.toJSON()
    query.type ?= 'octoblu:flow'
    query.owner ?= meshbluConfig.uuid
    meshbluHttp.devices query, (error, body) =>
      return callback 'unauthorized' if error?.message == 'unauthorized'
      return callback 'unable to get triggers' if error?

      triggers = @triggerModel.parseTriggersFromDevices body.devices
      callback null, triggers

  getTriggerByName: (name, callback=->) =>
    query = flow: '$elemMatch': name: name
    debug 'get triggers by name', query
    @getMyTriggers query, (error, triggers) =>
      debug 'got triggers', error, _.size(triggers), _.pluck(triggers, 'name')
      return callback error if error?
      debug 'searching for name', name
      trigger = _.find triggers, name: name
      debug 'trigger', trigger
      return callback new Error("No trigger by that name") unless trigger?
      callback null, trigger

module.exports = Triggers
