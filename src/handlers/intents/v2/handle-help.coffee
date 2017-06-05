class HandleHelp
  constructor: ({ @request, @response }) ->
    throw new Error 'Missing request' unless @request?
    throw new Error 'Missing response' unless @response?

  handle: (callback) =>
    @response.say "Tell Alexa a command to trigger a flow in Octoblu. If you are experiencing problems, make sure that your Octoblu account is properly linked and that you have linked your echo device properly"
    @response.shouldEndSession false, "Please say the command you wish to perform"
    callback null

module.exports = HandleHelp
