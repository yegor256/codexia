'usee strict'

const { AsyncObject } = require('@cuties/cutie')
const promiseToCallback = require('promise-to-callback')

class ExecutedLiquibaseMigrations extends AsyncObject {
  constructor (liquibase, optionsFilePath) {
    super(liquibase, optionsFilePath)
  }

  asyncCall () {
    return (liquibase, optionsFilePath, callback) => {
      promiseToCallback(
        liquibase({
          'defaultsFile': optionsFilePath
        }).run('update')
      )(callback)
    }
  }

  onResult () {
    return 1
  }
}

module.exports = ExecutedLiquibaseMigrations
