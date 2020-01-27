'use strict'

const { as } = require('@cuties/cutie')
const { Assertion } = require('@cuties/assert')
const { IsNumber } = require('@cuties/is')
const FreeRandomPort = require('./../../../src/async/net/FreeRandomPort')

new Assertion(
  new IsNumber(
    new FreeRandomPort()
  )
).call()
