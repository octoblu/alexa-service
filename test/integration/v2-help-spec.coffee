{describe,beforeEach,afterEach,expect,it} = global
request       = require 'request'
enableDestroy = require 'server-destroy'
shmock        = require 'shmock'
uuid          = require 'uuid'
Server        = require '../../src/server'

describe 'Help (v2)', ->
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
    describe 'when the AMAZON.HelpIntent', ->
      beforeEach (done) ->
        deviceAuth = new Buffer('device-uuid:device-token').toString('base64')

        options =
          uri: '/v2/trigger'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            session:
              sessionId: uuid.v1(),
              application:
                applicationId: "application-id"
              user:
                userId: "user-id",
                accessToken: deviceAuth
              new: true
            request:
              type: "IntentRequest",
              requestId: uuid.v1(),
              timestamp: "2016-02-12T19:28:15Z",
              intent:
                name: "AMAZON.HelpIntent"

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            directives: []
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>Tell Alexa a command to trigger a flow in Octoblu. If you are experiencing problems, make sure that your Octoblu account is properly linked and that you have linked your echo device properly</speak>'
            reprompt:
              outputSpeech:
                type: "SSML"
                ssml: "<speak>Please say the command you wish to perform</speak>"
            shouldEndSession: false

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200
