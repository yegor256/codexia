'use strict'

const { NotFoundEndpoint } = require('@cuties/rest')

class CustomNotFoundEndpoint extends NotFoundEndpoint {
  constructor (regexpUrl) {
    super(regexpUrl)
  }

  body (request, response) {
    return super.body(request, response)
  }
}

module.exports = CustomNotFoundEndpoint
