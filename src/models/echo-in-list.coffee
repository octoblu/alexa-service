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
      echoIn.fromNode { flowId, node }
      @_nodes.push echoIn

  names: =>
    list = _.map @echoIns, (echoIn) =>
      return echoIn.name
    return list.join ', and '

  toString: =>
    return EMPTY_LIST if _.isEmpty @echoIns
    return "Your triggers are #{@_names()}. Say a trigger name to perform the action"

module.exports = EchoInList
