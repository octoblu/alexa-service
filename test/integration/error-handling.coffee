request    = require 'request'
shmock     = require '@octoblu/shmock'
Server     = require '../../src/server'

describe 'HandleErrors', ->
  beforeEach (done) ->
    @restService = shmock 0xbabe
    @meshblu = shmock 0xd00d

    meshbluConfig =
      server: 'localhost'
      port: 0xd00d
      protocol: 'http'
      keepAlive: false

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

  afterEach (done) ->
    @meshblu.close done

  describe 'POST /dev/blow-up', ->
    describe 'when successful', ->
      beforeEach (done) ->
        options =
          uri: '/dev/blow-up'
          baseUrl: "http://localhost:#{@serverPort}"
          json: true

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            outputSpeech:
              type: 'PlainText'
              text: 'Oh No'
            shouldEndSession: true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200
