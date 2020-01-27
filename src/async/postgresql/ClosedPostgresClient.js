'use strict'

const { AsyncObject } = require('@cuties/cutie')

class ClosedPostgresClient extends AsyncObject {
  constructor (client) {
    super(client)
  }

  syncCall () {
    return (client) => {
      client.end()
      return client
    }
  }
}

module.exports = ClosedPostgresClient
