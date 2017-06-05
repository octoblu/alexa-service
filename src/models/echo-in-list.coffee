_      = require 'lodash'
EchoIn = require './echo-in'

EMPTY_LIST="You don't have any echo-in triggers. Get started by importing one or more alexa bluprints."

class EchoInList
  fromFlows: (flows) =>
    @_nodes ?= []
    _.each flows, (flow) =>
      flowId = flow.uuid
      return if _.isEmpty flow?.flow?.nodes
      nodes = _.filter flow.flow.nodes, { type: 'operation:echo-in' }
      @fromNodes flowId, nodes

  fromNodes: (flowId, nodes) =>
    @_nodes ?= []
    _.each nodes, (node) =>
      echoIn = new EchoIn()
      echoIn.fromJSON { flowId, node }
      @_nodes.push echoIn

  toString: =>
    return EMPTY_LIST if _.isEmpty @_nodes
    return "Your triggers are #{@_names()}. Say a trigger name to perform the action"

  _names: =>
    list = _.map @_nodes, (echoIn) =>
      return echoIn.name()
    return list.join ', and '

  findByName: (name) =>
    name = @sanifyStr name
    return _.find @_nodes, (node) =>
      return node.saneName() == name

  sanifyStr: (str) =>
    return '' unless _.isString str
    return str.trim().toLowerCase()

module.exports = EchoInList
