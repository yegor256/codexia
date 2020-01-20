'use strict'

const { Endpoint } = require('@cuties/rest')

const {
  ResponseWithHeader,
  ResponseWithStatusCode,
  ResponseWithStatusMessage,
  WrittenResponse,
  EndedResponse
} = require('@cuties/http')
const { StringifiedJSON } = require('@cuties/json')

class CheckPostgresConnectionEndpoint extends Endpoint {
  constructor (regexpUrl, postgresClient) {
    super(regexpUrl, 'GET')
    this.postgresClient = postgresClient
  }

  body (request, response) {
    return new EndedResponse(
      new WrittenResponse(
        new ResponseWithHeader(
          new ResponseWithStatusMessage(
            new ResponseWithStatusCode(response, 200), 'OK'
          ),
          'Content-Type', 'application/json'
        ),
        new StringifiedJSON(
          this.postgresClient
        )
      )
    )
  }
}

module.exports = CheckPostgresConnectionEndpoint
