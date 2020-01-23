'use strict'

const PulledPostgresByDocker = require('./../../../src/async/dockerized-postgres/PulledPostgresByDocker')
const { StrictEqualAssertion } = require('@cuties/assert')

new StrictEqualAssertion(
  new PulledPostgresByDocker(), 0
).call()
