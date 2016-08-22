_ = require 'lodash'

class EchoIn
  fromNode: ({ @flowId, @node }) =>

  name: =>
    return @node.name

  saneName: =>
    return '' unless _.isString @node.name
    return @node.name.trim().toLowerCase()

  buildMessage: ({responseId, baseUrl}, data) =>
    throw Error 'Missing responseId' unless responseId?
    throw Error 'Missing baseUrl' unless baseUrl?
    throw Error 'Missing flowId' unless @flowId?
    throw Error 'Missing Echo-In ID' unless @node?.id?
    payload = {
      callbackUrl: "#{baseUrl}/respond/#{responseId}"
      callbackMethod: "POST"
      responseId,
      from: @node.id
      payload: data
      params: data
    }
    return {
      devices: [ @flowId ]
      topic: 'triggers-service'
      payload
    }

module.exports = EchoIn
