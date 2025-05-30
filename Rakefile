# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rubygems'
require 'rake'
require 'rdoc'
require 'rake/clean'

ENV['RACK_ENV'] = 'test'

task default: %i[clean test eslint rubocop xcop copyright]

require 'rake/testtask'
Rake::TestTask.new(test: %i[pgsql liquibase]) do |test|
  Rake::Cleaner.cleanup_files(['coverage'])
  ENV['TEST_QUIET_LOG'] = 'true' if ARGV.include?('--quiet')
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.warning = false
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
  task.requires << 'rubocop-rspec'
end

require 'eslintrb/eslinttask'
Eslintrb::EslintTask.new(:eslint) do |t|
  t.pattern = 'js/**/*.js'
  t.options = :defaults
end

require 'pgtk/pgsql_task'
Pgtk::PgsqlTask.new(:pgsql) do |t|
  t.dir = 'target/pgsql'
  t.fresh_start = true
  t.user = 'test'
  t.password = 'test'
  t.dbname = 'test'
  t.yaml = 'target/pgsql-config.yml'
end

require 'pgtk/liquibase_task'
Pgtk::LiquibaseTask.new(:liquibase) do |t|
  t.master = 'liquibase/master.xml'
  t.yaml = ['target/pgsql-config.yml', 'config.yml']
end

require 'xcop/rake_task'
Xcop::RakeTask.new(:xcop) do |task|
  task.license = 'LICENSE.txt'
  task.includes = ['**/*.xml', '**/*.xsl', '**/*.xsd', '**/*.html']
  task.excludes = ['target/**/*', 'coverage/**/*']
end

desc 'Check the quality of config file'
task(:config) do
  YAML.safe_load(File.open('config.yml')).to_yaml
end

task(run: %i[pgsql liquibase]) do
  `rerun -b "RACK_ENV=test ruby codexia.rb"`
end

task(:copyright) do
  sh "grep -q -r '#{Date.today.strftime('%Y')}' \
    --include '*.rb' \
    --include '*.txt' \
    --include 'Rakefile' \
    ."
end
