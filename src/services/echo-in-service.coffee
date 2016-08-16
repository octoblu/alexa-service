_           = require 'lodash'
EchoInList  = require '../models/echo-in-list'
MeshbluHttp = require 'meshblu-http'

class EchoInService
  constructor: ({ meshbluConfig }) ->
    @owner = meshbluConfig.uuid
    @meshblu = new MeshbluHttp meshbluConfig

  message: (message, callback) =>
    @meshblu.message message, callback

  list: (callback) =>
    query = {
      type: 'octoblu:flow'
      online: true
      owner,
    }
    projection = {
      'uuid': true
      'name': true
      'flow.nodes': true
    }
    @meshblu.search query, { projection }, (error, flows) =>
      return callback error if error?
      echoInList = new EchoInList()
      echoInList.fromFlows flows
      callback null, echoInList

module.exports = EchoInService
