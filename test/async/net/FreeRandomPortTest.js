'use strict'

const { Assertion } = require('@cuties/assert')
const { IsNumber } = require('@cuties/is')
const FreeRandomPort = require('./../../../src/async/net/FreeRandomPort')

new Assertion(
  new IsNumber(
    new FreeRandomPort()
  )
).call()
