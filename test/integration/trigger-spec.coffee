request    = require 'request'
shmock     = require '@octoblu/shmock'
Server     = require '../../src/server'

describe 'Trigger', ->
  beforeEach (done) ->
    @restService = shmock 0xbabe

    meshbluConfig =
      server: 'localhost'
      port: 0xd00d

    serverOptions =
      port: undefined,
      disableLogging: true
      meshbluConfig: meshbluConfig
      restServiceUri: "http://localhost:#{0xbabe}"

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach (done) ->
    @server.stop done

  afterEach (done) ->
    @restService.close done

  describe 'POST /trigger', ->
    describe 'when successful', ->
      beforeEach (done) ->
        userAuth = new Buffer('user-uuid:user-token').toString('base64')

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
          .reply 200, responseText: 'THIS IS THE RESPONSE TEXT'

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
              text: 'THIS IS THE RESPONSE TEXT'
            shouldEndSession: true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should hit up the rest service', ->
        @respondWithRestService.done()

    describe 'when rest service times out', ->
      beforeEach (done) ->
        userAuth = new Buffer('user-uuid:user-token').toString('base64')

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
