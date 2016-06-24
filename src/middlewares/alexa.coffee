crypto    = require 'crypto'
url       = require 'url'
async     = require 'async'
x509      = require 'x509'
validator = require 'validator'
moment    = require 'moment'
NodeRSA   = require 'node-rsa'

class Alexa
  set: ({ @testAlexaCertObject, @alexaCert }) =>

  verify: =>
    return @middleware

  middleware: (req, res, next) =>
    certUrl = req.headers.signaturecertchainurl
    signature = req.headers.signature
    rawBody = req.rawBody
    jsonBody = req.body
    @getCert { certUrl }, (error, cert) =>
      return res.status(400).send @convertError error if error?
      async.series [
        async.apply @validateCert, { cert }
        async.apply @validateSignature, { cert, signature, rawBody }
        async.apply @validateTimestamp, { jsonBody }
      ], (error) =>
        return res.status(400).send @convertError error if error?
        next()

  validateCertUrl: ({ certUrl }, callback) =>
    return callback 'missing-cert-url' unless certUrl
    urlObject = url.parse certUrl
    return callback('invalid-cert-url-protocol') unless urlObject.protocol == 'https:'
    return callback('invalid-cert-url-hostname') unless urlObject.hostname == 's3.amazonaws.com'
    return callback('invalid-cert-url-path') unless urlObject.pathname == '/echo.api/echo-api-cert.pem'
    return callback('invalid-cert-url-port') if urlObject.port? && urlObject.port != 443
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
    @validateCertUrl { certUrl }, (error) =>
      return callback error if error?
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

  convertError: (error) =>
    return status: 'failure', reason: error

module.exports = new Alexa
