'usee strict'

const { AsyncObject } = require('@cuties/cutie')

class MappedPortOfPostgresContainer extends AsyncObject {
  constructor (container) {
    super(container)
  }

  syncCall () {
    return (container) => {
      return container.getMappedPort(5432)
    }
  }
}

module.exports = MappedPortOfPostgresContainer
