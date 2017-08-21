{describe,beforeEach,afterEach,expect,it} = global
request       = require 'request'
enableDestroy = require 'server-destroy'
shmock        = require 'shmock'
uuid          = require 'uuid'
Server        = require '../../src/server'

describe 'Open Intent', ->
  beforeEach (done) ->
    @meshblu = shmock 0xd00d
    enableDestroy(@meshblu)

    meshbluConfig =
      server: 'localhost'
      port: 0xd00d
      protocol: 'http'
      keepAlive: false

    serverOptions =
      port: undefined,
      disableLogging: true
      meshbluConfig: meshbluConfig
      disableAlexaVerification: true
      namespace: 'alexa-service:test'
      alexaServiceUri: 'https://alexa.octoblu.dev'

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @meshblu.destroy()
    @server.destroy()

  describe 'POST /trigger', ->
    describe 'when it has auth', ->
      beforeEach (done) ->
        sessionId = uuid.v1()
        requestId = uuid.v1()
        userAuth = new Buffer('user-uuid:user-token').toString('base64')

        options =
          uri: '/trigger'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            session:
              sessionId: sessionId,
              application:
                applicationId: "application-id"
              user:
                userId: "user-id",
                accessToken: userAuth
              new: true
            request:
              type: "LaunchRequest",
              requestId: requestId,
              timestamp: "2016-02-12T19:28:15Z"

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            directives: []
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>Welcome, this skill allows you to trigger an Octoblu flow that perform a series of events or actions</speak>'
            shouldEndSession: false

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

    describe 'when missing auth', ->
      beforeEach (done) ->
        sessionId = uuid.v1()
        requestId = uuid.v1()

        options =
          uri: '/trigger'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            session:
              sessionId: sessionId
              application:
                applicationId: "application-id"
              user:
                userId: "user-id",
              new: true
            request:
              type: "LaunchRequest",
              requestId: requestId,
              timestamp: "2016-02-12T19:28:15Z",

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            directives: []
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>Welcome, this skill allows you to trigger an Octoblu flow that perform a series of events or actions</speak>'
            shouldEndSession: false

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200
