'use strict'

const ConnectedPostgresClient = require('./../../../src/async/postgresql/ConnectedPostgresClient')
const { Assertion } = require('@cuties/assert')
const { Is } = require('@cuties/is')

class FakePostgresClient {
  constructor () { }

  connect () { }
}

new Assertion(
  new Is(
    new ConnectedPostgresClient({
      'user': 'user',
      'host': 'localhost',
      'port': 5432,
      'password': 1234,
      'database': 'db'
    }, FakePostgresClient),
    FakePostgresClient
  )
).call()
