request    = require 'request'
shmock     = require '@octoblu/shmock'
Server     = require '../../src/server'

describe 'Respond', ->
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

  describe 'POST /respond/:responseId', ->
    beforeEach (done) ->
      @respondWithRestService = @restService
        .post '/respond/my-response-id'
        .send name: 'Freedom'
        .reply 200, success: true

      options =
        uri: '/respond/my-response-id'
        baseUrl: "http://localhost:#{@serverPort}"
        json:
          name: 'Freedom'

      request.post options, (error, @response, @body) =>
        done error

    it 'should hit up the rest service', ->
      @respondWithRestService.done()

    it 'should respond with 200', ->
      expect(@response.statusCode).to.equal 200

    it 'should have a body', ->
      expect(@body).to.deep.equal success: true
