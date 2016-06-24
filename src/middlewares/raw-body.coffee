class RawBody
  generate: =>
    return @middleware

  middleware: (request, response, next) =>
    data = ''
    request.on 'data', (chunk) =>
      data += chunk
    request.on 'end', =>
      request.rawBody = data
    next()

module.exports = new RawBody
