_   = require 'lodash'
URL = require 'url'

class EchoDevice
  constructor: ({ @alexaServiceUri }) ->
    throw new Error 'EchoDevice: requires alexaServiceUri' unless @alexaServiceUri?

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

  buildMessage: ({ type, sessionId, responseId }, data) =>
    throw Error 'Missing responseId' unless responseId?
    throw Error 'Missing sessionId' unless sessionId?
    throw Error 'Missing type' unless type?
    throw Error 'Missing uuid' unless @uuid?
    return {
      devices: [ @uuid ]
      topic: 'echo-request'
      metadata: {
        callbackUrl: @_getAlexaUri { pathname: "/v2/respond/#{responseId}" }
        callbackMethod: "POST"
        responseId,
        sessionId,
        type,
      }
      data: data,
    }

  getUpdateDeviceProperties: ({ owner }) =>
    return {
      $set:
        'schemas.version': "2.0.0"
        'schemas.form':
          $ref: @_getAlexaUri { pathname: '/schemas/form' }
        'schemas.message':
          $ref: @_getAlexaUri { pathname: '/schemas/message' }
        'schemas.configure':
          $ref: @_getAlexaUri { pathname: '/schemas/configure' }
        'meshblu.version': "2.0.0"
        'octoblu.flow.forwardMetadata': true
        type: 'alexa:echo-device'
        iconUri: 'http://icons.octoblu.com/device/echo-device.svg'
        online: true
      $addToSet:
        'meshblu.whitelists.broadcast.as': { uuid: owner }
        'meshblu.whitelists.broadcast.received': { uuid: owner }
        'meshblu.whitelists.broadcast.sent': { uuid: owner }
        'meshblu.whitelists.configure.as': { uuid: owner }
        'meshblu.whitelists.configure.received': { uuid: owner }
        'meshblu.whitelists.configure.sent': { uuid: owner }
        'meshblu.whitelists.configure.update': { uuid: owner }
        'meshblu.whitelists.discover.view': { uuid: owner }
        'meshblu.whitelists.discover.as': { uuid: owner }
        'meshblu.whitelists.message.as': { uuid: owner }
        'meshblu.whitelists.message.received': { uuid: owner }
        'meshblu.whitelists.message.sent': { uuid: owner }
        'meshblu.whitelists.message.from': { uuid: owner }
    }

  _getAlexaUri: ({ pathname }) =>
    urlOptions = URL.parse(@alexaServiceUri)
    urlOptions.pathname = pathname
    return URL.format(urlOptions)

module.exports = EchoDevice
