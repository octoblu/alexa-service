OPEN_MESSAGE="Welcome, this skill allows you to trigger an Octoblu flow that perform a series of events or actions"

class HandleLaunchRequest
  constructor: ({ @meshbluConfig, request, @response }) ->
    throw new Error 'Missing request' unless request?
    throw new Error 'Missing response' unless @response?

  handle: (callback) =>
    @response.say OPEN_MESSAGE
    @response.shouldEndSession false
    callback null

module.exports = HandleLaunchRequest
