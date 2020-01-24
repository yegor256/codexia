'use strict'

const { AsyncObject } = require('@cuties/cutie')

class Sleep extends AsyncObject {
  constructor (ms) {
    super(ms)
  }

  asyncCall () {
    return (ms, callback) => {
      setTimeout(callback, ms)
    }
  }

  onResult () {
    return 0
  }
}

module.exports = Sleep
