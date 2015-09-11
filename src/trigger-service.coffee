_               = require 'lodash'
uuid            = require 'node-uuid'
MeshbluHttp     = require 'meshblu-http'
TriggerModel    = require './trigger-model'
debug           = require('debug')('alexa-service:triggers-service')

class Triggers
  constructor: (@meshbluConfig={}) ->
    @triggerModel = new TriggerModel()

  trigger: (triggerId, flowId, requestId, params, callback=->) =>
    debug 'trigger trigger'
    meshbluHttp = new MeshbluHttp @meshbluConfig

    message =
      devices: [flowId]
      topic: 'triggers-service'
      payload:
        from: triggerId
        params: params
        requestId: requestId
    debug 'trigger message', message
    meshbluHttp.message message, callback

  getMyTriggers: (query={}, callback=->) =>
    debug 'getting my triggers', query
    meshbluHttp = new MeshbluHttp @meshbluConfig
    query.type ?= 'octoblu:flow'
    query.owner ?= @meshbluConfig.uuid
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
      trigger = _.first triggers
      debug 'trigger', trigger
      return callback new Error("No trigger by that name") unless trigger?
      callback null, trigger

module.exports = Triggers
