'use strict'

const { AsyncObject } = require('@cuties/cutie')
const net = require('net')

class FreeRandomPort extends AsyncObject {
  constructor () {
    super()
  }

  asyncCall () {
    return (callback) => {
      this.server = net.createServer()
      this.server.listen(0, callback)
    }
  }

  onResult () {
    const port = this.server.address().port
    this.server.close()
    return port
  }
}

module.exports = FreeRandomPort
