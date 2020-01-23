'usee strict'

const { AsyncObject } = require('@cuties/cutie')
const { exec } = require('child_process')

class KilledPostgresContainer extends AsyncObject {
  constructor (container) {
    super(container)
  }

  asyncCall () {
    return (container, callback) => {
      this.container = container
      exec(`docker kill ${container}`, callback)
    }
  }

  onErrorAndResult (error, stdout) {
    if (error) {
      console.log(`container ${this.container} is already killed`)
    } else {
      console.log('Postgres is shutdown')
      console.log(stdout)
    }
    return 0
  }

  continueAfterFail () {
    return true
  }
}

module.exports = KilledPostgresContainer
