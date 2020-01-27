'use strict'

const { AsyncObject } = require('@cuties/cutie')

class ConnectedPostgresClient extends AsyncObject {
  constructor (PGClientModule, options) {
    super(PGClientModule, options)
  }

  syncCall () {
    return (PGClientModule, options) => {
      const client = new PGClientModule(options)
      client.connect()
      return client
    }
  }
}

module.exports = ConnectedPostgresClient
