{describe,beforeEach,afterEach,expect,it} = global
request       = require 'request'
enableDestroy = require 'server-destroy'
shmock        = require 'shmock'
uuid          = require 'uuid'
Server        = require '../../src/server'

describe 'Invalid Intent (v2)', ->
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
      alexaServiceUri: 'https://alexa.octoblu.dev'
      namespace: 'alexa-service:test'
      disableAlexaVerification: true

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @meshblu.destroy()
    @server.destroy()

  describe 'POST /v2/trigger', ->
    describe 'when successful', ->
      beforeEach (done) ->
        sessionId = uuid.v1()
        deviceAuth = new Buffer('device-uuid:device-token').toString('base64')

        @authenticate = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{deviceAuth}"
          .reply 200, uuid: 'device-uuid', token: 'device-token'

        options =
          uri: '/v2/trigger'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            session:
              sessionId: sessionId,
              application:
                applicationId: "application-id"
              user:
                userId: "user-id",
                accessToken: deviceAuth
              new: true
            request:
              type: "IntentRequest",
              requestId: uuid.v1(),
              timestamp: "2016-02-12T19:28:15Z"
              intent:
                name: "Something"

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            directives: []
            outputSpeech:
              type: 'SSML'
              ssml: "<speak>No trigger to reply to</speak>"
            shouldEndSession: true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200
