'usee strict'

const { AsyncObject } = require('@cuties/cutie')

class ConnectedPostgresClient extends AsyncObject {
  constructor (ClientModule, options) {
    super(ClientModule, options)
  }

  syncCall () {
    return (ClientModule, options) => {
      const client = new ClientModule(options)
      client.connect()
      return client
    }
  }
}

module.exports = ConnectedPostgresClient
