'use strict'

const {
  Event
} = require('@cuties/cutie')

class NotFoundErrorEvent extends Event {
  constructor (notFoundEndpoint, request, response) {
    super()
    this.notFoundEndpoint = notFoundEndpoint
    this.request = request
    this.response = response
  }

  body (error) {
    this.notFoundEndpoint.body(this.request, this.response, error).call()
  }
}

module.exports = NotFoundErrorEvent
