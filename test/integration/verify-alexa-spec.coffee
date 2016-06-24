request       = require 'request'
enableDestroy = require 'server-destroy'
shmock        = require '@octoblu/shmock'
fs            = require 'fs'
path          = require 'path'
moment        = require 'moment'
Encrypto      = require '../encrypto'
Server        = require '../../src/server'
testCerts     = require '../test-certs.json'

describe 'Verify Alexa', ->
  beforeEach (done) ->
    @restService = shmock 0xbabe
    @meshblu = shmock 0xd00d
    enableDestroy(@meshblu)
    enableDestroy(@restService)

    @encrypto = new Encrypto testCerts

    meshbluConfig =
      server: 'localhost'
      port: 0xd00d
      protocol: 'http'
      keepAlive: false

    @testAlexaCertObject = {
      notAfter: new Date(Date.now() + (10 * 1000))
      altNames: ['echo-api.amazon.com']
      publicKey: testCerts.publicKey
    }

    serverOptions =
      port: undefined,
      disableLogging: true
      meshbluConfig: meshbluConfig
      restServiceUri: "http://localhost:#{0xbabe}"
      disableAlexaVerification: false
      alexaCert: testCerts.publicKey
      testAlexaCertObject: @testAlexaCertObject

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @meshblu.destroy()
    @restService.destroy()
    @server.destroy()

  describe 'POST /verify/trigger', ->
    beforeEach ->
      userAuth = new Buffer('user-uuid:user-token').toString('base64')

      @whoami = @meshblu
        .post '/authenticate'
        .set 'Authorization', "Basic #{userAuth}"
        .reply 200, uuid: 'user-uuid', token: 'user-token'

      @getDevices = @meshblu
        .get '/v2/devices'
        .set 'Authorization', "Basic #{userAuth}"
        .query owner: 'user-uuid', type: 'octoblu:flow', online: 'true'
        .reply 200, [
          {online: true, flow: nodes: [{name: 'sweet', type: 'operation:echo-in'}]}
          {online: true, flow: nodes: [{name: 'yay', type: 'operation:echo-in'}]}
        ]

      @requestOptions =
        uri: '/verify/trigger'
        baseUrl: "http://localhost:#{@serverPort}"
        headers: {
          'SignatureCertChainUrl': 'https://s3.amazonaws.com/echo.api/echo-api-cert.pem'
        }
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
            type: "LaunchRequest",
            requestId: "request-id",
            timestamp: moment().toISOString()

      @requestOptions.headers.Signature = @encrypto.sign @requestOptions.json

    describe 'when it is successful', ->
      beforeEach (done) ->
        request.post @requestOptions, (error, @response, @body) =>
          done error

      it 'should have the correct body response', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            outputSpeech:
              type: 'PlainText'
              text: 'This skill allows you to trigger an Octoblu flow that perform a series of events or actions. Currently, Your triggers are sweet, and yay. Say a trigger name to perform the action'
            shouldEndSession: false

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should hit up the rest service', ->
        @getDevices.done()

      it 'should hit up whoami', ->
        @whoami.done()

    describe 'when the request has an invalid cert url', ->
      describe 'when it is missing', ->
        beforeEach (done) ->
          delete @requestOptions.headers.SignatureCertChainUrl
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 400', ->
          expect(@response.statusCode).to.equal 400

        it 'should respond with an appropriate reason', ->
          expect(@body.reason).to.equal 'missing-cert-url'

      describe 'when it is not https', ->
        beforeEach (done) ->
          @requestOptions.headers['SignatureCertChainUrl'] = 'http://s3.amazonaws.com/echo.api/echo-api-cert.pem'
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 400', ->
          expect(@response.statusCode).to.equal 400

        it 'should respond with an appropriate reason', ->
          expect(@body.reason).to.equal 'invalid-cert-url-protocol'

      describe 'when it has an invalid hostname', ->
        beforeEach (done) ->
          @requestOptions.headers['SignatureCertChainUrl'] = 'https://notamazon.com/echo.api/echo-api-cert.pem'
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 400', ->
          expect(@response.statusCode).to.equal 400

        it 'should respond with an appropriate reason', ->
          expect(@body.reason).to.equal 'invalid-cert-url-hostname'

      describe 'when it has an invalid path', ->
        beforeEach (done) ->
          @requestOptions.headers['SignatureCertChainUrl'] = 'https://s3.amazonaws.com/EcHo.aPi/echo-api-cert.pem'
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 400', ->
          expect(@response.statusCode).to.equal 400

        it 'should respond with an appropriate reason', ->
          expect(@body.reason).to.equal 'invalid-cert-url-path'

      describe 'when it has an obvious invalid path', ->
        beforeEach (done) ->
          @requestOptions.headers['SignatureCertChainUrl'] = 'https://s3.amazonaws.com/invalid.path/echo-api-cert.pem'
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 400', ->
          expect(@response.statusCode).to.equal 400

        it 'should respond with an appropriate reason', ->
          expect(@body.reason).to.equal 'invalid-cert-url-path'

      describe 'when it has an obvious invalid port', ->
        beforeEach (done) ->
          @requestOptions.headers['SignatureCertChainUrl'] = 'https://s3.amazonaws.com:563/echo.api/echo-api-cert.pem'
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 400', ->
          expect(@response.statusCode).to.equal 400

        it 'should respond with an appropriate reason', ->
          expect(@body.reason).to.equal 'invalid-cert-url-port'

    describe 'when the request has an invalid cert', ->
      describe 'when it is not before', ->
        beforeEach (done) ->
          @testAlexaCertObject.notBefore = new Date(Date.now() + (10 * 1000))
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 400', ->
          expect(@response.statusCode).to.equal 400

        it 'should respond with an appropriate reason', ->
          expect(@body.reason).to.equal 'cert-not-active-yet'

      describe 'when it is not after', ->
        beforeEach (done) ->
          @testAlexaCertObject.notAfter = new Date(Date.now() - (10 * 1000))
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 400', ->
          expect(@response.statusCode).to.equal 400

        it 'should respond with an appropriate reason', ->
          expect(@body.reason).to.equal 'cert-expired'

      describe 'when it has an invalid SANs', ->
        beforeEach (done) ->
          @testAlexaCertObject.altNames = ['not-echo-api.amazon.com']
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 400', ->
          expect(@response.statusCode).to.equal 400

        it 'should respond with an appropriate reason', ->
          expect(@body.reason).to.equal 'invalid-alt-names'

      describe 'when it has an invalid signature format', ->
        beforeEach (done) ->
          @requestOptions.headers.Signature = 'not-base64'
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 400', ->
          expect(@response.statusCode).to.equal 400

        it 'should respond with an appropriate reason', ->
          expect(@body.reason).to.equal 'invalid-signature-format'

      describe 'when it has a invalid signature', ->
        beforeEach (done) ->
          @requestOptions.headers.Signature = @encrypto.sign '{"this.will":"fail"}'
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 400', ->
          expect(@response.statusCode).to.equal 400

        it 'should respond with an appropriate reason', ->
          expect(@body.reason).to.equal 'invalid-signature'

      describe 'when it has a valid signature', ->
        beforeEach (done) ->
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 200', ->
          expect(@response.statusCode).to.equal 200

    describe 'when the request has an invalid timestamp', ->
      describe 'when it is missing', ->
        beforeEach (done) ->
          delete @requestOptions.json.request.timestamp
          @requestOptions.headers.Signature = @encrypto.sign @requestOptions.json
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 200', ->
          expect(@response.statusCode).to.equal 200

      describe 'when it is more than 150 seconds ago', ->
        beforeEach (done) ->
          @requestOptions.json.request.timestamp = moment().subtract('151', 'seconds').toISOString()
          @requestOptions.headers.Signature = @encrypto.sign @requestOptions.json
          request.post @requestOptions, (error, @response, @body) =>
            done error

        it 'should respond with a 400', ->
          expect(@response.statusCode).to.equal 400

        it 'should respond with an appropriate reason', ->
          expect(@body.reason).to.equal 'timestamp-is-outside-of-tolerance'
