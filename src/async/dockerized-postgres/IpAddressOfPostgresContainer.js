'usee strict'

const { AsyncObject } = require('@cuties/cutie')

class IpAddressOfContainer extends AsyncObject {
  constructor (container) {
    super(container)
  }

  syncCall () {
    return (container) => {
      return container.getContainerIpAddress()
    }
  }
}

module.exports = IpAddressOfContainer
