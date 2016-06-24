crypto       = require 'crypto'
url          = require 'url'
async        = require 'async'
x509         = require 'x509'
validator    = require 'validator'
request      = require 'request'
moment       = require 'moment'
normalizeUrl = require 'normalize-url'
debug        = require('debug')('alexa-service:validate-alexa-requests')

class Alexa
  constructor: () ->
    @certs = {}

  verify: ({ @testCert }) =>
    return @middleware

  middleware: (request, response, next) =>
    return @sendBadReason response, 'missing-cert-url' unless request.headers.signaturecertchainurl
    certUrl = normalizeUrl request.headers.signaturecertchainurl
    signature = request.headers.signature
    rawBody = request.rawBody
    jsonBody = request.body
    debug 'verifying requests', { certUrl, signature }
    @getCert { certUrl }, (reason, certResponse) =>
      return @sendBadReason response, reason if reason?
      async.series [
        async.apply @validateCert, certResponse
        async.apply @validateSignature, certResponse, { signature, rawBody }
        async.apply @validateTimestamp, { jsonBody }
      ], (reason) =>
        return @sendBadReason response, reason if reason?
        debug 'valid request'
        next()

  validateCertUrl: ({ certUrl }, callback) =>
    {protocol,hostname,pathname,port} = url.parse certUrl
    return callback 'invalid-cert-url-protocol' unless protocol == 'https:'
    return callback 'invalid-cert-url-hostname' unless hostname == 's3.amazonaws.com'
    return callback 'invalid-cert-url-path' unless pathname.indexOf('/echo.api/') == 0
    return callback 'invalid-cert-url-port' if port? && port != 443
    callback()

  validateCert: ({ cert }, callback) =>
    { notBefore, notAfter, altNames } = cert
    debug 'validate cert properties', { notBefore, notAfter, altNames }
    return callback 'cert-not-active-yet' if moment().isBefore notBefore
    return callback 'cert-expired' if moment().isAfter notAfter
    return callback 'invalid-alt-names' unless 'echo-api.amazon.com' in altNames
    callback null

  validateSignature: ({ body }, { signature, rawBody }, callback) =>
    debug 'validating signature', signature
    return callback 'invalid-signature-format' unless validator.isBase64 signature
    verifier = crypto.createVerify('SHA1').update rawBody
    return callback 'invalid-signature' unless verifier.verify(body, signature, 'base64')
    callback()

  getCert: ({ certUrl }, callback) =>
    return callback null, @certs[certUrl] if @certs[certUrl]?
    debug 'getting cert'
    @validateCertUrl { certUrl }, (reason) =>
      return callback reason if reason?
      return callback null, @testCert if @testCert?
      debug 'getting certUrl', certUrl
      request.get certUrl, (error, response, body) =>
        debug 'got cert url response error', { error } if error?
        return callback 'cert-retrieval-error' if error?
        debug 'got cert url response.statusCode', response.statusCode
        return callback 'cert-retrieval-invalid-response' unless response.statusCode == 200
        cert = x509.parseCert body
        @certs[certUrl] = { cert, body }
        callback null, { cert, body }

  validateTimestamp: ({ jsonBody={} }, callback) =>
    { timestamp } = jsonBody.request ? {}
    return callback() unless timestamp?
    tolerance = moment().subtract(150, 'seconds')
    return callback 'timestamp-is-outside-of-tolerance' if moment(timestamp).isBefore tolerance
    callback()

  sendBadReason: (response, reason) =>
    responseObj = { status: 'failure', reason }
    debug 'bad request', { reason }
    response.status(400).send responseObj

module.exports = new Alexa
