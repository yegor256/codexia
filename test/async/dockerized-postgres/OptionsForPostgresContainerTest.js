'use strict'

const OptionsForPostgresContainer = require('./../../../src/async/dockerized-postgres/OptionsForPostgresContainer')
const { DeepStrictEqualAssertion } = require('@cuties/assert')

new DeepStrictEqualAssertion(
  new OptionsForPostgresContainer(
    'containerName', 'port', 'user', 'db', 'password'
  ),
  {
    'containerName': 'containerName',
    'port': 'port:5432',
    'user': 'user',
    'db': 'db',
    'password': 'password'
  }
).call()
