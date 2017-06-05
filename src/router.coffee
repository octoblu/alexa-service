AlexaController    = require './controllers/alexa-controller'
V2AlexaController  = require './controllers/v2-alexa-controller'

class Router
  constructor: ({timeoutSeconds,meshbluConfig, alexaServiceUri}) ->
    throw new Error 'Missing meshbluConfig' unless meshbluConfig?
    throw new Error 'Missing alexaServiceUri' unless alexaServiceUri?
    @alexaController = new AlexaController {timeoutSeconds,meshbluConfig, alexaServiceUri}
    @v2AlexaController = new V2AlexaController {timeoutSeconds,meshbluConfig, alexaServiceUri}

  route: (app) =>
    app.post '/trigger', @alexaController.trigger
    app.post '/respond/:responseId', @alexaController.respond

    app.post '/v2/trigger', @v2AlexaController.trigger
    app.post '/v2/respond/:responseId', @v2AlexaController.respond

module.exports = Router
