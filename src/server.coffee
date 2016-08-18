_                  = require 'lodash'
cors               = require 'cors'
morgan             = require 'morgan'
express            = require 'express'
errorHandler       = require 'errorhandler'
bodyParser         = require 'body-parser'
enableDestroy      = require 'server-destroy'
sendError          = require 'express-send-error'
alexa              = require './middlewares/alexa'
rawBody            = require './middlewares/raw-body'
RedisNs            = require '@octoblu/redis-ns'
redis              = require 'redis'
JobLogger          = require 'job-logger'
{ Pool }           = require 'generic-pool'
PooledJobManager   = require 'meshblu-core-pooled-job-manager'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
Router             = require './router'
debug              = require('debug')('alexa-service:server')

class Server
  constructor: (options)->
    {@disableLogging, @port} = options
    {@meshbluConfig,@alexaServiceUri} = options
    {@disableAlexaVerification} = options
    {@testCert} = options
    {@redisUri, @namespace, @jobTimeoutSeconds} = options
    {@jobLogRedisUri, @jobLogQueue} = options
    {@jobLogSampleRate} = options
    {@logError} = options
    throw new Error 'Missing meshbluConfig' unless @meshbluConfig?
    throw new Error 'Missing alexaServiceUri' unless @alexaServiceUri?
    throw new Error 'Missing jobLogRedisUri' unless @jobLogRedisUri?
    throw new Error 'Missing jobLogQueue' unless @jobLogQueue?
    throw new Error 'Missing namespace' unless @namespace?
    throw new Error 'Missing jobTimeoutSeconds' unless @jobTimeoutSeconds?

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use meshbluHealthcheck()
    app.use sendError()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use cors()
    app.use errorHandler()
    app.use rawBody.generate()
    app.use bodyParser.json limit : '1mb', defer: true

    app.options '*', cors()

    app.use '/trigger', alexa.verify { @testCert } unless @disableAlexaVerification

    jobLogger = new JobLogger
      jobLogQueue: @jobLogQueue
      indexPrefix: 'metric:alexa-service'
      type: 'alexa-service:request'
      client: redis.createClient(@jobLogRedisUri)

    connectionPool = @_createConnectionPool()
    jobManager = new PooledJobManager
      timeoutSeconds: @jobTimeoutSeconds
      jobLogSampleRate: @jobLogSampleRate || 1
      pool: connectionPool
      jobLogger: jobLogger

    router = new Router {@logError, @meshbluConfig,@alexaServiceUri,jobManager}
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
