'use strict'

const { as } = require('@cuties/cutie')
const { Assertion } = require('@cuties/assert')
const { IsNumber } = require('@cuties/is')
const { ReadDataByPath } = require('@cuties/fs')
const { ParsedJSON } = require('@cuties/json')
const { Value } = require('@cuties/object')
const ConnectedPostgresClient = require('./../../../src/async/postgresql/ConnectedPostgresClient')
const ClosedPostgresClient = require('./../../../src/async/postgresql/ClosedPostgresClient')
const PGClient = require('pg').Client
const SavedUser = require('./../../../src/async/db-domain/SavedUser')
const SavedProject = require('./../../../src/async/db-domain/SavedProject')
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
  new Value(
    new SavedUser(
      as('PG_CLIENT'), login, avatarUrl
    ),
    'login'
  ).as('SAVED_USER_LOGIN').after(
    new SavedProject(
      as('PG_CLIENT'),
      as('SAVED_USER_LOGIN'),
      'userName/projectName',
      'github'
    ).as('SAVED_PROJECT').after(
      new Assertion(
        new IsNumber(
          new Value(
            as('SAVED_PROJECT'),
            'id'
          )
        )
      ).after(
        new ClosedPostgresClient(
          as('PG_CLIENT')
        )
      )
    )
  )
).call()
