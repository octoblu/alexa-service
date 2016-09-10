redis              = require 'redis'
cors               = require 'cors'
_                  = require 'lodash'
morgan             = require 'morgan'
express            = require 'express'
onFinished         = require 'on-finished'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
{ Pool }           = require 'generic-pool'
enableDestroy      = require 'server-destroy'
RedisNs            = require '@octoblu/redis-ns'
sendError          = require 'express-send-error'
expressVersion     = require 'express-package-version'
meshbluHealthcheck = require 'express-meshblu-healthcheck'

Router             = require './router'
alexa              = require './middlewares/alexa'
rawBody            = require './middlewares/raw-body'
debug              = require('debug')('alexa-service:server')

class Server
  constructor: (options)->
    {@disableLogging,@port} = options
    {@meshbluConfig,@alexaServiceUri} = options
    {@disableAlexaVerification} = options
    {@timeoutSeconds,@redisUri, @namespace} = options
    {@testCert} = options
    throw new Error 'Missing meshbluConfig' unless @meshbluConfig?
    throw new Error 'Missing namespace' unless @namespace?
    throw new Error 'Missing alexaServiceUri' unless @alexaServiceUri?

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use meshbluHealthcheck()
    app.use expressVersion { format: '{"version": "%s"}' }
    app.use sendError()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use cors()
    app.use errorHandler()
    app.use rawBody.generate()
    app.use bodyParser.json limit : '1mb', defer: true

    app.options '*', cors()

    app.use '/trigger', alexa.verify { @testCert } unless @disableAlexaVerification

    pool = @_createConnectionPool()

    app.use (request, response, next) =>
      pool.acquire (error, client) =>
        delete error.code if error?
        return next error if error?
        request.redisClient = client
        onFinished response, =>
          pool.release client
        next()

    router = new Router {@timeoutSeconds, @meshbluConfig, @alexaServiceUri }
    router.route app

    @server = app.listen @port, callback

    enableDestroy(@server)

  _createConnectionPool: =>
    connectionPool = new Pool
      max: @connectionPoolMaxConnections
      min: 0
      returnToHead: true # sets connection pool to stack instead of queue behavior
      create: (callback) =>
        client = _.bindAll new RedisNs @namespace, redis.createClient(@redisUri)
        client.on 'end', ->
          client.hasError = new Error 'ended'

        client.on 'error', (error) ->
          client.hasError = error
          callback error if callback?

        client.once 'ready', ->
          callback null, client
          callback = null

      destroy: (client) => client.end true
      validate: (client) => !client.hasError?

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
