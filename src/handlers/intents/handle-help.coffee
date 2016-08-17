class HandleHelp
  constructor: ({ @request, @response }) ->

  handle: (callback) =>
    @response.say "Tell Alexa to trigger a flow by saying the name of your Echo in thing. If you are experiencing problems, make sure that your Octoblu account is properly linked and that you have your triggers named properly"
    @response.shouldEndSession false, "Please say the name of a trigger associated with your account"
    callback null

module.exports = HandleHelp
