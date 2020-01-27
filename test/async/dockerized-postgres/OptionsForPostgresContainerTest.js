'use strict'

const OptionsForPostgresContainer = require('./../../../src/async/dockerized-postgres/OptionsForPostgresContainer')
const { DeepStrictEqualAssertion } = require('@cuties/assert')

new DeepStrictEqualAssertion(
  new OptionsForPostgresContainer(
    'containerName', 'user', 'db', 'password'
  ),
  {
    'containerName': 'containerName',
    'user': 'user',
    'db': 'db',
    'password': 'password'
  }
).call()
