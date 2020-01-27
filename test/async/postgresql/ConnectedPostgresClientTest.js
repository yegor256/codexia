'use strict'

const { as } = require('@cuties/cutie')
const { Assertion } = require('@cuties/assert')
const { Is } = require('@cuties/is')
const { ReadDataByPath } = require('@cuties/fs')
const { ParsedJSON } = require('@cuties/json')
const ConnectedPostgresClient = require('./../../../src/async/postgresql/ConnectedPostgresClient')
const ClosedPostgresClient = require('./../../../src/async/postgresql/ClosedPostgresClient')
const PGClient = require('pg').Client

new Assertion(
  new Is(
    new ConnectedPostgresClient(
      PGClient,
      new ParsedJSON(
        new ReadDataByPath(
          './target/postgres/config.json',
          { 'encoding': 'utf8' }
        )
      )
    ).as('PG_CLIENT'),
    PGClient
  )
).after(
  new ClosedPostgresClient(
    as('PG_CLIENT')
  )
).call()
