'use strict'

const { as } = require('@cuties/cutie')
const { StrictEqualAssertion } = require('@cuties/assert')
const { ReadDataByPath } = require('@cuties/fs')
const { ParsedJSON } = require('@cuties/json')
const { Value } = require('@cuties/object')
const ConnectedPostgresClient = require('./../../../src/async/postgresql/ConnectedPostgresClient')
const ClosedPostgresClient = require('./../../../src/async/postgresql/ClosedPostgresClient')
const PGClient = require('pg').Client
const SavedUser = require('./../../../src/async/db-domain/SavedUser')
const uuidv4 = require('uuid/v4')

const login = uuidv4()
const avatarUrl = uuidv4()

new ConnectedPostgresClient(
  PGClient,
  new ParsedJSON(
    new ReadDataByPath(
      './test-tmp/postgres.json',
      { 'encoding': 'utf8' }
    )
  )
).as('PG_CLIENT').after(
  new StrictEqualAssertion(
    new Value(
      new SavedUser(
        as('PG_CLIENT'), login, avatarUrl
      ),
      'login'
    ),
    login
  ).after(
    new ClosedPostgresClient(
      as('PG_CLIENT')
    )
  )
).call()
