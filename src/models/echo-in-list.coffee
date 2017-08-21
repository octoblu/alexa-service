_          = require 'lodash'
EchoIn     = require './echo-in'
{ filter } = require 'fuzzaldrin'

EMPTY_LIST="You don't have any echo-in triggers. Get started by importing one or more alexa bluprints."
TRIGGER_PROMPT="Say a trigger name to perform the action"

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
    count = _.size(@_nodes)
    if count == 1
      return "You have an available trigger, #{@_names()}. #{TRIGGER_PROMPT}"
    if count == 2
      return "You have two available triggers, #{@_names()}. #{TRIGGER_PROMPT}"
    return "You have the following available triggers, #{@_names()}. #{TRIGGER_PROMPT}"

  _names: =>
    list = _.map @_nodes, (echoIn) =>
      return echoIn.name()
    return list.join ', and '

  findByName: (name) =>
    query = @sanifyStr name
    nodeList = _.map @_nodes, (node) =>
      return {
        name: node.saneName()
        node: node,
      }
    result = filter nodeList, query, { maxResults: 1, key: 'name' }
    matched = _.first result
    return _.get matched, 'node'

  sanifyStr: (str) =>
    return '' unless _.isString str
    return str.trim().toLowerCase()

module.exports = EchoInList
