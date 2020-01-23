'usee strict'

const { AsyncObject } = require('@cuties/cutie')
const { exec } = require('child_process')

class PulledPostgresByDocker extends AsyncObject {
  constructor () {
    super()
  }

  asyncCall () {
    return (callback) => {
      exec('sudo docker pull postgres', callback)
    }
  }

  onResult (stdout) {
    console.log(stdout)
    return 0
  }
}

module.exports = PulledPostgresByDocker
