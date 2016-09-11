_ = require 'lodash'

class EchoIn
  fromJSON: (str) =>
    { @flowId, @node } = JSON.parse str

  toJSON: =>
    return JSON.stringify { @flowId, @node }

  fromNode: ({ @flowId, @node }) =>

  name: =>
    return @node.name

  saneName: =>
    return '' unless _.isString @node.name
    return @node.name.trim().toLowerCase()

  buildMessage: ({ type, sessionId, responseId, baseUrl}, data) =>
    throw Error 'Missing responseId' unless responseId?
    throw Error 'Missing sessionId' unless sessionId?
    throw Error 'Missing type' unless type?
    throw Error 'Missing baseUrl' unless baseUrl?
    throw Error 'Missing flowId' unless @flowId?
    throw Error 'Missing Echo-In ID' unless @node?.id?
    payload = {
      callbackUrl: "#{baseUrl}/respond/#{responseId}"
      callbackMethod: "POST"
      responseId,
      sessionId,
      type,
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
