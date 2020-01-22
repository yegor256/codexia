'use strict'

const { as } = require('@cuties/cutie')
const { Backend, RestApi, ServingFilesEndpoint } = require('@cuties/rest')
const { ReadDataByPath } = require('@cuties/fs')
const { ParsedJSON, Value } = require('@cuties/json')
const { Created } = require('@cuties/created')
const { Client } = require('pg')
const CustomNotFoundEndpoint = require('./endpoints/CustomNotFoundEndpoint')
const CustomInternalServerErrorEndpoint = require('./endpoints/CustomInternalServerErrorEndpoint')
const CustomIndexEndpoint = require('./endpoints/CustomIndexEndpoint')
const CheckPostgresConnectionEndpoint = require('./endpoints/CheckPostgresConnectionEndpoint')
const ConnectedPostgresClient = require('./async/postgresql/ConnectedPostgresClient')
const notFoundEndpoint = new CustomNotFoundEndpoint(new RegExp(/\/not-found/))
const path = require('path')
const ExecutedLiquibaseMigrations = require('./async/liquibase/ExecutedLiquibaseMigrations')
const liquibase = require('liquibase')
const env = process.env.NODE_ENV || 'test'

const mapper = (url) => {
  return path.join('src', 'static', ...url.split('?')[0].split('/').filter(path => path !== ''))
}

new ExecutedLiquibaseMigrations(
  liquibase,
  new Value(
    new Value(
      new ParsedJSON(
        new ReadDataByPath(
          './postgres.env.json',
          { 'encoding': 'utf8' }
        )
      ),
      env
    ),
    'liquibase'
  )
).after(
  new Logged('liquibase migrations are applied').after(
    new ConnectedPostgresClient(
      Client,
      new Value(
        new ParsedJSON(
          new ReadDataByPath(
            'postgres.env.json',
            { 'encoding': 'utf8' }
          )
        ), env
      )
    ).as('POSTGRES_CLIENT').after(
      new Backend(
        'http',
        8000,
        '0.0.0.0',
        new RestApi(
          new CustomIndexEndpoint('./src/static/html/index.html', notFoundEndpoint),
          new ServingFilesEndpoint(new RegExp(/^\/(html|css|js|images)/), mapper, {}, notFoundEndpoint),
          new Created(CheckPostgresConnectionEndpoint, new RegExp(/^\/(postgres)/), as('POSTGRES_CLIENT')),
          notFoundEndpoint,
          new CustomInternalServerErrorEndpoint(new RegExp(/^\/internal-server-error/))
        )
      )
    )
  )
).call()
