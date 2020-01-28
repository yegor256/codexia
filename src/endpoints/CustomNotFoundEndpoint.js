'use strict'

const { CreatedReadStream } = require('@cuties/fs')
const { ResponseWithStatusCode, ResponseWithHeader } = require('@cuties/http')
const { PipedReadable } = require('@cuties/stream')
const { NotFoundEndpoint } = require('@cuties/rest')

class CustomNotFoundEndpoint extends NotFoundEndpoint {
  constructor (regexpUrl, page) {
    super(regexpUrl)
    this.page = page
  }

  body (request, response) {
    return new PipedReadable(
      new CreatedReadStream(
        this.page
      ),
      new ResponseWithStatusCode(
        new ResponseWithHeader(
          response, 'Content-Type',
          'text/html'
        ), 404
      )
    )
  }
}

module.exports = CustomNotFoundEndpoint
