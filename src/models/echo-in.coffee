class EchoIn
  fromNode: ({ @flowId, @node }) =>

  name: =>
    return @node.name

  message: (data, callback) =>
    throw Error 'Missing flowId' unless @flowId
    throw Error 'Missing Echo-In ID' unless @node?.id
    payload = {
      from: @node.id
      payload: data
      params: data
    }
    return {
      devices: [ @flowId ]
      topic: 'alexa-service'
      payload
    }

module.exports = EchoIn
