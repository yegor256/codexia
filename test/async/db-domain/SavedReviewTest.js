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
const SavedReview = require('./../../../src/async/db-domain/SavedReview')
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
    new Value(
      new SavedProject(
        as('PG_CLIENT'),
        as('SAVED_USER_LOGIN'),
        'userName/projectName',
        'github'
      ),
      'id'
    ).as('SAVED_PROJECT_ID').after(
      new SavedReview(
        as('PG_CLIENT'),
        as('SAVED_PROJECT_ID'),
        as('SAVED_USER_LOGIN'),
        'review text'
      ).as('SAVED_REVIEW').after(
        new Assertion(
          new IsNumber(
            new Value(
              as('SAVED_REVIEW'),
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
  )
).call()
