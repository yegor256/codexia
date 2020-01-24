'use strict'

const { AsyncObject } = require('@cuties/cutie')

class Sleep extends AsyncObject {
  constructor (ms) {
    super(ms)
  }

  asyncCall () {
    return (ms, callback) => {
      console.log('sleep start')
      setTimeout(callback, ms)
    }
  }

  onResult () {
    console.log('sleep end')
    return 0
  }
}

module.exports = Sleep
