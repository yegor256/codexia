'use strict'

const {
  ExecutedLint,
  ExecutedTestCoverageCheck,
  ExecutedTestCoverage
} = require('@cuties/wall')
const { ParsedJSON, Value } = require('@cuties/json')
const { ReadDataByPath } = require('@cuties/fs')
const ExecutedLiquibaseMigrations = require('./async/liquibase/ExecutedLiquibaseMigrations')
const liquibase = require('liquibase')
const env = process.env.NODE_ENV || 'test'

new ExecutedLint(
  process,
  './src/app.js',
  './src/build.js',
  './src/async',
  './src/endpoints',
  './src/events'
).after(
  new ExecutedTestCoverageCheck(
    new ExecutedTestCoverage(process, './test.js'),
    { 'lines': 100, 'functions': 100, 'branches': 100 }
  ).after(
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
    )
  )
).call()
