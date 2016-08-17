request    = require 'request'
redis      = require 'redis'
RedisNs    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'
Server     = require '../../src/server'

describe 'Respond', ->
  beforeEach (done) ->
    meshbluConfig =
      server: 'localhost'
      port: 0xd00d
      protocol: 'http'
      keepAlive: false

    serverOptions =
      port: undefined,
      disableLogging: true
      meshbluConfig: meshbluConfig
      jobTimeoutSeconds: 1
      namespace: 'alexa-service:test'
      jobLogQueue: 'alexa-service:job-log'
      jobLogRedisUri: 'redis://localhost:6379'
      alexaServiceUri: 'https://alexa.octoblu.dev'
      disableAlexaVerification: false

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

    client = new RedisNs 'alexa-service:test', redis.createClient()
    @jobManager = new JobManager { client, timeoutSeconds: 1, jobLogSampleRate: 1 }

  afterEach ->
    @server.destroy()

  describe 'POST /respond/:responseId', ->
    describe 'when successful', ->
      beforeEach (done) ->
        options =
          uri: '/respond/my-response-id'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            name: 'Freedom'

        request.post options, (error, @response, @body) =>
          throw error if error?
          @jobManager.getResponse 'response', 'my-response-id', (error, @result) =>
            done error

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should have a body', ->
        expect(@body).to.deep.equal success: true

      it 'should have the response of Freedom', ->
        expect(JSON.parse(@result.rawData).name).to.equal 'Freedom'

    describe 'when incorrect job key', ->
      beforeEach (done) ->
        options =
          uri: '/respond/wrong-response-id'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            name: 'Freedom'

        request.post options, (error, @response, @body) =>
          throw error if error?
          @jobManager.getResponse 'response', 'right-response-id', (@error) =>
            done()

      it 'should have a timeout error', ->
        expect(@error.message).to.equal 'Response timeout exceeded'
