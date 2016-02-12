_            = require 'lodash'
url          = require 'url'
uuid         = require 'node-uuid'
MeshbluHttp  = require 'meshblu-http'
TriggerModel = require './trigger-model'
debug        = require('debug')('alexa-service:triggers-service')

class Triggers
  constructor: (@meshbluConfig={}) ->
    @triggerModel = new TriggerModel()
    @HOSTNAME = process.env.HOSTNAME
    @PORT = process.env.PORT ? process.env.ALEXA_PORT
    @PROTOCOL = "http"

  trigger: (triggerId, flowId, requestId, params, callback=->) =>
    debug 'trigger trigger'
    meshbluHttp = new MeshbluHttp @meshbluConfig
    urlOptions =
      hostname: @HOSTNAME ? 'localhost'
      port: @PORT
      protocol: @PROTOCOL
      pathname: "/respond/#{requestId}"

    callbackUrl = url.format urlOptions
    message =
      devices: [flowId]
      topic: 'triggers-service'
      payload:
        from: triggerId
        params: params
        requestId: requestId
        callbackUrl: callbackUrl
    debug 'trigger message', message
    meshbluHttp.message message, callback

  getFlows: (query={}, callback=->) =>
    meshbluHttp = new MeshbluHttp @meshbluConfig
    query.type ?= 'octoblu:flow'
    query.owner ?= @meshbluConfig.uuid
    debug 'getting my triggers', query
    meshbluHttp.devices query, (error, body) =>
      return callback 'unauthorized' if error?.message == 'unauthorized'
      return callback 'unable to get triggers' if error?
      callback null, body

  parseFlowsForTriggers: (flows={}, callback=->) =>
    return @triggerModel.parseTriggersFromDevices flows

  getTriggerByName: (name, callback=->) =>
    query = 'flow.nodes': '$elemMatch': name: name
    debug 'get triggers by name', query
    @getFlows query, (error, body=[]) =>
      return callback error if error?
      flows = _.filter body, online: true
      return callback new Error("Flow is offline, please deploy.") unless _.size(flows)
      triggers = @parseFlowsForTriggers flows
      debug 'got triggers', error, _.size(triggers), _.pluck(triggers, 'name')
      debug 'searching for name', name
      trigger = _.find triggers, name: name
      debug 'trigger', trigger
      return callback new Error("No trigger by that name") unless trigger?
      callback null, trigger

module.exports = Triggers
