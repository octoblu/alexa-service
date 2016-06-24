crypto    = require 'crypto'
url       = require 'url'
async     = require 'async'
x509      = require 'x509'
validator = require 'validator'
moment    = require 'moment'
NodeRSA   = require 'node-rsa'
debug     = require('debug')('alexa-service:validate-alexa-requests')

class Alexa
  set: ({ @testAlexaCertObject, @alexaCert }) =>

  verify: =>
    return @middleware

  middleware: (request, response, next) =>
    certUrl = request.headers.signaturecertchainurl
    signature = request.headers.signature
    rawBody = request.rawBody
    jsonBody = request.body
    debug 'verifying requests', { certUrl, signature }
    @getCert { certUrl }, (reason, cert) =>
      return @sendBadReason response, reason if reason?
      async.series [
        async.apply @validateCert, { cert }
        async.apply @validateSignature, { cert, signature, rawBody }
        async.apply @validateTimestamp, { jsonBody }
      ], (reason) =>
        return @sendBadReason response, reason if reason?
        debug 'valid request'
        next()

  validateCertUrl: ({ certUrl }, callback) =>
    return callback 'missing-cert-url' unless certUrl
    urlObject = url.parse certUrl
    return callback 'invalid-cert-url-protocol' unless urlObject.protocol == 'https:'
    return callback 'invalid-cert-url-hostname' unless urlObject.hostname == 's3.amazonaws.com'
    return callback 'invalid-cert-url-path' unless urlObject.pathname == '/echo.api/echo-api-cert.pem'
    return callback 'invalid-cert-url-port' if urlObject.port? && urlObject.port != 443
    callback()

  validateCert: ({ cert }, callback) =>
    return callback 'cert-not-active-yet' if moment().isBefore cert.notBefore
    return callback 'cert-expired' if moment().isAfter cert.notAfter
    return callback 'invalid-alt-names' unless 'echo-api.amazon.com' in cert.altNames
    callback null

  validateSignature: ({ cert, signature, rawBody }, callback) =>
    return callback 'invalid-signature-format' unless validator.isBase64 signature
    key = new NodeRSA(cert.publicKey)
    hash = crypto.createHash 'sha1'
    hash.update rawBody.toString()
    bodySignature = hash.digest 'hex'
    verified = key.verify(bodySignature, signature, null, 'base64')
    return callback 'invalid-signature' unless verified
    callback()

  getCert: ({ certUrl }, callback) =>
    @validateCertUrl { certUrl }, (reason) =>
      return callback reason if reason?
      return callback null, @testAlexaCertObject if @testAlexaCertObject
      request.get certUrl, (error, response, body) =>
        return callback 'cert-retrieval-error' if error?
        return callback 'cert-retrieval-invalid-response' unless response.statusCode == 200
        callback null, x509.parseCert body.toString()

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
