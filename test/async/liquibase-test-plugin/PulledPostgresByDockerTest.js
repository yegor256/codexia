'use strict'

const PulledPostgresByDocker = require('./../../../src/async/liquibase-test-plugin/PulledPostgresByDocker')
const { StrictEqualAssertion } = require('@cuties/assert')

new StrictEqualAssertion(
  new PulledPostgresByDocker(), 0
).call()
