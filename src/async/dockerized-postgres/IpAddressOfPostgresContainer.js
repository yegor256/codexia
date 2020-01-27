'usee strict'

const { AsyncObject } = require('@cuties/cutie')

class IpAddressOfPostgresContainer extends AsyncObject {
  constructor (container) {
    super(container)
  }

  syncCall () {
    return (container) => {
      return container.getContainerIpAddress()
    }
  }
}

module.exports = IpAddressOfPostgresContainer
