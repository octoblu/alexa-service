_               = require 'lodash'
AlexaController = require './controllers/alexa-controller'

class Router
  constructor: ({@meshbluConfig,@restServiceUri}) ->
    @alexaController = new AlexaController {@meshbluConfig,@restServiceUri}

  route: (app) =>
    app.post '/trigger', @alexaController.trigger
    app.post '/respond/:responseId', @alexaController.respond

module.exports = Router
