request       = require 'request'
enableDestroy = require 'server-destroy'
shmock        = require 'shmock'
Server        = require '../../src/server'

describe 'Invalid Intent', ->
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
      disableAlexaVerification: true

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @meshblu.destroy()
    @server.destroy()

  describe 'POST /trigger', ->
    describe 'when successful', ->
      beforeEach (done) ->
        options =
          uri: '/trigger'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            session:
              sessionId: "session-id",
              application:
                applicationId: "application-id"
              user:
                userId: "user-id",
                accessToken: "should-not-matter"
              new: true
            request:
              type: "IntentRequest",
              requestId: "request-id",
              timestamp: "2016-02-12T19:28:15Z"
              intent:
                name: "Something"

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          sessionAttributes: {}
          response:
            outputSpeech:
              type: 'SSML'
              ssml: "<speak>Sorry, the application didn't know what to do with that intent.</speak>"
            reprompt:
              outputSpeech:
                type: "SSML"
                ssml: "<speak>Please say the name of a trigger associated with your account</speak>"
            shouldEndSession: true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

    describe 'when missing any triggers', ->
      beforeEach (done) ->
        options =
          uri: '/trigger'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            session:
              sessionId: "session-id",
              application:
                applicationId: "application-id"
              user:
                userId: "user-id",
                accessToken: "should-not-matter"
              new: true
            request:
              type: "IntentRequest",
              requestId: "request-id",
              timestamp: "2016-02-12T19:28:15Z",
              intent:
                name: "Something"

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          sessionAttributes: {}
          response:
            outputSpeech:
              type: 'SSML'
              ssml: "<speak>Sorry, the application didn't know what to do with that intent.</speak>"
            reprompt:
              outputSpeech:
                type: "SSML"
                ssml: "<speak>Please say the name of a trigger associated with your account</speak>"
            shouldEndSession: true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

