_  = require 'lodash'

TIMEOUT = 9 * 1000

class PendingRequests
  constructor: ->
    @requests = {}
    @timeouts = {}

  get: (key) =>
    return @requests[key]

  set: (key, value, timeoutCallback=->) =>
    @requests[key] = value
    @timeouts[key] = _.delay @timeout, TIMEOUT, key, timeoutCallback

  remove: (key) =>
    delete @requests[key]
    clearTimeout @timeouts[key]
    delete @timeouts[key]

  timeout: (key, callback=->) =>
    value = @get key
    return unless value?
    @remove key
    callback value

module.exports = PendingRequests
