_ = require 'lodash'

class EchoDevice
  fromRawJSON: (str) =>
    { @uuid, @name } = JSON.parse str

  toJSON: =>
    return JSON.stringify { @uuid, @name }

  fromJSON: ({ @uuid, @name }) =>

  name: =>
    return @name

  saneName: =>
    return '' unless _.isString @name
    return @name.trim().toLowerCase()

  buildMessage: ({ type, sessionId, responseId, baseUrl }, data) =>
    throw Error 'Missing responseId' unless responseId?
    throw Error 'Missing sessionId' unless sessionId?
    throw Error 'Missing type' unless type?
    throw Error 'Missing baseUrl' unless baseUrl?
    throw Error 'Missing uuid' unless @uuid?
    return {
      devices: [ @uuid ]
      topic: 'echo-request'
      metadata: {
        callbackUrl: "#{baseUrl}/v2/respond/#{responseId}"
        callbackMethod: "POST"
        responseId,
        sessionId,
        type,
      }
      data: data,
    }

module.exports = EchoDevice
