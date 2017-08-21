class HandleHelp
  constructor: ({ @request, @response }) ->
    throw new Error 'Missing request' unless @request?
    throw new Error 'Missing response' unless @response?

  handle: (callback) =>
    @response.say "Tell Alexa to trigger a flow by saying the name of the desired trigger. If you are experiencing problems, make sure that your Octoblu account is properly linked and that you have your triggers named properly"
    @response.shouldEndSession false
    callback null

module.exports = HandleHelp
