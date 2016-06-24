_                  = require 'lodash'
AlexaController    = require './controllers/alexa-controller'
{ CLOSE_RESPONSE } = require './models/responses'

class Router
  constructor: ({@meshbluConfig,@restServiceUri}) ->
    @alexaController = new AlexaController {@meshbluConfig,@restServiceUri}

  doAndHandleErrors: (route) =>
    return (req, res) =>
      try
        route req, res
      catch error
        console.error error
        response = _.cloneDeep CLOSE_RESPONSE
        response.response.outputSpeech.text = error?.message ? error
        res.status(200).send response

  route: (app) =>
    app.post '/trigger', @doAndHandleErrors @alexaController.trigger
    app.post '/respond/:responseId', @doAndHandleErrors @alexaController.respond
    app.post '/dev/blow-up', @doAndHandleErrors () =>
      throw new Error('Oh No')

module.exports = Router
