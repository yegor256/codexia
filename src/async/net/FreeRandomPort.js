'use strict'

const { AsyncObject } = require('@cuties/cutie')
const portfinder = require('portfinder')

class FreeRandomPort extends AsyncObject {
  constructor (minPort = 1000, maxPort = 9999) {
    super(minPort, maxPort)
  }

  asyncCall () {
    return (minPort, maxPort, callback) => {
      portfinder.getPort({
        port: minPort,
        stopPort: maxPort
      }, callback)
    }
  }
}

module.exports = FreeRandomPort
