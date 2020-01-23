'usee strict'

const { AsyncObject } = require('@cuties/cutie')
const promiseToCallback = require('promise-to-callback')

class AppliedLiquibaseMigrations extends AsyncObject {
  constructor (liquibase, options) {
    super(liquibase, options)
  }

  asyncCall () {
    return (liquibase, options, callback) => {
      promiseToCallback(
        liquibase(options).run('update')
      )(callback)
    }
  }

  onResult () {
    return 1
  }
}

module.exports = AppliedLiquibaseMigrations
