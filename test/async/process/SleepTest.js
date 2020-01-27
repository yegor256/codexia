'use strict'

const { StrictEqualAssertion } = require('@cuties/assert')
const Sleep = require('./../../../src/async/process/Sleep')

new StrictEqualAssertion(
  new Sleep(10),
  0
).call()
