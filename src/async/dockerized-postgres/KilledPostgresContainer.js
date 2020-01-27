'usee strict'

const { AsyncObject } = require('@cuties/cutie')
const promiseToCallback = require('promise-to-callback')

class KilledPostgresContainer extends AsyncObject {
  constructor (container) {
    super(container)
  }

  asyncCall () {
    return (container, callback) => {
      this.container = container
      promiseToCallback(
        container.stop()
      )(callback)
    }
  }
}

module.exports = KilledPostgresContainer
