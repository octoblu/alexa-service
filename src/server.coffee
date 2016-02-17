cors               = require 'cors'
morgan             = require 'morgan'
express            = require 'express'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
Router             = require './router'
debug              = require('debug')('alexa-service:server')

class Server
  constructor: (options)->
    {@disableLogging, @port} = options
    {@meshbluConfig,@restServiceUri} = options

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use meshbluHealthcheck()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use cors()
    app.use errorHandler()
    app.use bodyParser.urlencoded limit: '1mb', extended : true, defer: true
    app.use bodyParser.json limit : '1mb', defer: true

    app.options '*', cors()

    router = new Router {@meshbluConfig,@restServiceUri}
    router.route app

    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

module.exports = Server
