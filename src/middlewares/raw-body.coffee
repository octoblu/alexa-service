class RawBody
  generate: () =>
    return (req, res, next) =>
      data = ''
      req.on 'data', (chunk) =>
        data += chunk
      req.on 'end', =>
        req.rawBody = data
      next()

module.exports = new RawBody
