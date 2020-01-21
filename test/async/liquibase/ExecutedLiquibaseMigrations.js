'use strict'

const ExecutedLiquibaseMigrations = require('./../../../src/async/liquibase/ExecutedLiquibaseMigrations')
const { StrictEqualAssertion } = require('@cuties/assert')

class FakeLiquibase {
  constructor (params = {}) {
    this.params = params
  }

  run () {
    return new Promise((resolve, reject) => { })
  }
}

const fakeLiquibase = params => new FakeLiquibase(params)

new StrictEqualAssertion(
  new ExecutedLiquibaseMigrations(
    fakeLiquibase, 'path/to/props'
  ),
  1
).call()

new StrictEqualAssertion(
  new ExecutedLiquibaseMigrations(
    fakeLiquibase, 'path/to/props'
  ).onResult(),
  1
).call()
