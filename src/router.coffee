AlexaController    = require './controllers/alexa-controller'

class Router
  constructor: ({timeoutSeconds,meshbluConfig, alexaServiceUri}) ->
    throw new Error 'Missing meshbluConfig' unless meshbluConfig?
    throw new Error 'Missing alexaServiceUri' unless alexaServiceUri?
    @alexaController = new AlexaController {timeoutSeconds,meshbluConfig, alexaServiceUri}

  route: (app) =>
    app.post '/trigger', @alexaController.trigger
    app.post '/respond/:responseId', @alexaController.respond

module.exports = Router
