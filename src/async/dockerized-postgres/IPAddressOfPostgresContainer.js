'usee strict'

const { AsyncObject } = require('@cuties/cutie')
const { exec } = require('child_process')

class IPAddressOfPostgresContainer extends AsyncObject {
  constructor (container) {
    super(container)
  }

  asyncCall () {
    return (container, callback) => {
      this.container = container
      exec(`sudo docker inspect -f "{{ .NetworkSettings.IPAddress }}" ${container}`, callback)
    }
  }

  onResult (ip) {
    return ip
  }
}

module.exports = IPAddressOfPostgresContainer
