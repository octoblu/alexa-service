_           = require 'lodash'
EchoInList  = require '../models/echo-in-list'
MeshbluHttp = require 'meshblu-http'
debug       = require('debug')('alexa-service:echo-in-service')

class EchoInService
  constructor: ({ meshbluConfig }) ->
    @owner = meshbluConfig.uuid
    @meshblu = new MeshbluHttp meshbluConfig

  message: (message, callback) =>
    debug 'messaging', message
    @meshblu.message message, callback

  list: (callback) =>
    query = {
      type: 'octoblu:flow'
      online: true
      @owner,
    }
    projection = {
      'uuid': true
      'name': true
      'flow.nodes': true
    }
    debug 'querying for echo ins', { query, projection }
    @meshblu.search query, { projection }, (error, flows) =>
      debug 'got flows', { error, count: _.size(flows) }
      return callback error if error?
      echoInList = new EchoInList()
      echoInList.fromFlows flows
      callback null, echoInList

module.exports = EchoInService
