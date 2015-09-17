_  = require 'lodash'

TIMEOUT = 8 * 1000 # 12 Seconds

class PendingRequests
  constructor: ->
    @requests = {}

  get: (key) =>
    return @requests[key]

  set: (key, value, timeoutCallback=->) =>
    @requests[key] = value
    _.delay @timeout, TIMEOUT, key, timeoutCallback

  remove: (key) =>
    delete @requests[key]

  timeout: (key, callback=->) =>
    value = @get key
    return unless value?
    @remove key
    callback value

module.exports = PendingRequests
