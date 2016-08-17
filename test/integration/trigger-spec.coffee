request       = require 'request'
enableDestroy = require 'server-destroy'
shmock        = require 'shmock'
Server        = require '../../src/server'

describe 'Trigger', ->
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
        userAuth = new Buffer('user-uuid:user-token').toString('base64')

        @whoami = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 200, uuid: 'user-uuid', token: 'user-token'

        @searchDevices = @meshblu
          .post '/search/devices'
          .set 'Authorization', "Basic #{userAuth}"
          .set 'X-MESHBLU-PROJECTION', JSON.stringify { uuid: true, 'flow.nodes': true }
          .send { owner: 'user-uuid', online: true, type: 'octoblu:flow' }
          .reply 200, [
            {
              uuid: 'hello',
              flow: {
                nodes: [
                  {
                    id: 'weather',
                    type: 'operation:echo-in',
                    name: 'the weather'
                  }
                  {
                    id: 'trip-report',
                    type: 'operation:echo-in',
                    name: 'the trip report'
                  }
                ]
              }
            }
            {
              uuid: 'bye',
              flow: {
                nodes: [
                  {
                    id: 'stock',
                    type: 'operation:echo-in',
                    name: 'the stock price'
                  }
                ]
              }
            }
          ]

        data = {
          type: "IntentRequest",
          requestId: "request-id",
          timestamp: "2016-02-12T19:28:15Z",
          intent:
            name: "Trigger",
            slots:
              Name:
                name: "Name",
                value: "the weather"
          }

        @message = @meshblu
          .post '/message'
          .set 'Authorization', "Basic #{userAuth}"
          .send {
            devices: ['hello']
            topic: 'alexa-service'
            payload:
              callbackUrl: "https://alexa.octoblu.dev/respond/request-id"
              callbackMethod: "POST"
              responseId: 'request-id'
              from: 'weather'
              params: data
              payload: data
          }
          .reply 200

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
                accessToken: userAuth
              new: true
            request:
              type: "IntentRequest",
              requestId: "request-id",
              timestamp: "2016-02-12T19:28:15Z",
              intent:
                name: "Trigger",
                slots:
                  Name:
                    name: "Name",
                    value: "the weather"

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          sessionAttributes: {}
          response:
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>THIS IS THE RESPONSE TEXT</speak>'
            shouldEndSession: true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should hit up whoami', ->
        @whoami.done()

      it 'should search for flows', ->
        @searchDevices.done()

      it 'should message the flow', ->
        @message.done()

    xdescribe 'when rest service times out', ->
      beforeEach (done) ->
        userAuth = new Buffer('user-uuid:user-token').toString('base64')

        @whoami = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 200, uuid: 'user-uuid', token: 'user-token'

        @respondWithRestService = @restService
          .post '/flows/triggers/the%20weather'
          .set 'Authorization', "Basic #{userAuth}"
          .set 'X-RESPONSE-BASE-URI', 'https://alexa.octoblu.com'
          .send {
            type: "IntentRequest",
            requestId: "request-id",
            timestamp: "2016-02-12T19:28:15Z",
            intent:
              name: "Trigger",
              slots:
                Name:
                  name: "Name",
                  value: "the weather"
          }
            .reply 408, error: 'Request timeout'

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
                accessToken: userAuth
              new: true
            request:
              type: "IntentRequest",
              requestId: "request-id",
              timestamp: "2016-02-12T19:28:15Z",
              intent:
                name: "Trigger",
                slots:
                  Name:
                    name: "Name",
                    value: "the weather"

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            outputSpeech:
              type: 'PlainText'
              text: 'Request timeout'
            shouldEndSession: true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should hit up the rest service', ->
        @respondWithRestService.done()

      it 'should hit up whoami', ->
        @whoami.done()


    xdescribe 'when missing auth', ->
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
                userId: "user-id"
              new: true
            request:
              type: "IntentRequest",
              requestId: "request-id",
              timestamp: "2016-02-12T19:28:15Z",
              intent:
                name: "Trigger",
                slots:
                  Name:
                    name: "Name",
                    value: "the weather"

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: "1.0"
          response:
            outputSpeech:
              type: "PlainText"
              text: "Please go to your Alexa app and link your account."
            card:
              type: "LinkAccount"

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

    xdescribe 'when invalid auth is provided', ->
      beforeEach (done) ->
        @whoami = @meshblu
          .post '/authenticate'
          .reply 403, error: message: 'Unauthorized'

        options =
          uri: '/trigger'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            session:
              sessionId: "session-id",
              application:
                applicationId: "application-id"
              user:
                userId: "user-id"
                accessToken: new Buffer('invalid-uuid:invalid-token').toString('base64')
              new: true
            request:
              type: "IntentRequest",
              requestId: "request-id",
              timestamp: "2016-02-12T19:28:15Z",
              intent:
                name: "Trigger",
                slots:
                  Name:
                    name: "Name",
                    value: "the weather"

        request.post options, (error, @response, @body) =>
          done error

      it 'should hit up whoami', ->
        @whoami.done()

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: "1.0"
          response:
            outputSpeech:
              type: "PlainText"
              text: "Please go to your Alexa app and link your account."
            card:
              type: "LinkAccount"

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200
