_                  = require 'lodash'
cors               = require 'cors'
morgan             = require 'morgan'
express            = require 'express'
errorHandler       = require 'errorhandler'
bodyParser         = require 'body-parser'
verifier           = require 'alexa-verifier'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
Router             = require './router'
debug              = require('debug')('alexa-service:server')

class Server
  constructor: (options)->
    {@disableLogging, @port} = options
    {@meshbluConfig,@restServiceUri} = options

  address: =>
    @server.address()

  getRawBody: (req, res, next) =>
    data = ''
    req.on 'data', (chunk) =>
      data += chunk
    req.on 'end', =>
      req.rawBody = data
    next()

  verifyAlexa: (req, res, next) =>
    return next() unless process.env.NODE_ENV == 'production'

    certUrl  = req.headers.signaturecertchainurl
    signature = req.headers.signature
    verifier certUrl, signature, req.rawBody, (error) ->
      return next() unless error?
      console.error 'error validating the alexa cert:', error
      res.status(401).json { status: 'failure', reason: error }

  run: (callback) =>
    app = express()
    app.use meshbluHealthcheck()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use cors()
    app.use errorHandler()
    app.use bodyParser.json limit : '1mb', defer: true

    app.options '*', cors()

    app.use @verifyAlexa

    router = new Router {@meshbluConfig,@restServiceUri}
    router.route app

    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

module.exports = Server
