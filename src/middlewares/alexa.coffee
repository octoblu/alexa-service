class Alexa
  verify: (req, res, next) =>
    certUrl  = req.headers.signaturecertchainurl
    signature = req.headers.signature
    verifier certUrl, signature, req.rawBody, (error) ->
      return next() unless error?
      console.error 'error validating the alexa cert:', error
      res.status(401).json { status: 'failure', reason: error }

module.exports = new Alexa
