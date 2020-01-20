'usee strict'

const { AsyncObject } = require('@cuties/cutie')
const { Pool, Client } = require('pg')

class ConnectedPostgresClient extends AsyncObject {
  constructor (options) {
    super(options)
  }

  syncCall () {
    return (options) => {
      const client = new Client(options)
      client.connect()
      return client
    }
  }
}

module.exports = ConnectedPostgresClient
