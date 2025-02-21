# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

STDOUT.sync = true

require 'glogin'
require 'glogin/codec'
require 'haml'
require 'iri'
require 'json'
require 'loog'
require 'pgtk'
require 'pgtk/pool'
require 'raven'
require 'relative_time'
require 'sinatra'
require 'sinatra/cookies'
require 'tacky'
require 'telepost'
require 'time'
require 'yaml'
require 'zache'
require 'alterout'
require_relative 'objects/urror'
require_relative 'objects/authors'
require_relative 'objects/projects'
require_relative 'version'

if ENV['RACK_ENV'] != 'test'
  require 'rack/ssl'
  use Rack::SSL
end

configure do
  Haml::Options.defaults[:format] = :xhtml
  config = {
    'github' => {
      'client_id' => '?',
      'client_secret' => '?',
      'encryption_secret' => ''
    },
    'zold' => {
      'token' => '?',
      'keygap' => '?'
    },
    'telegram' => {
      'token' => '?',
      'channel' => '?'
    },
    'sentry' => ''
  }
  config = YAML.safe_load(File.open(File.join(File.dirname(__FILE__), 'config.yml'))) unless ENV['RACK_ENV'] == 'test'
  if ENV['RACK_ENV'] != 'test'
    Raven.configure do |c|
      c.dsn = config['sentry']
      c.release = Xia::VERSION
    end
  end
  disable :raise_errors
  disable :show_exceptions
  enable :logging
  set :bind, '0.0.0.0'
  set :server, :thin
  set :dump_errors, ENV['RACK_ENV'] == 'test'
  set :config, config
  set :logging, true
  set :log, ENV['TEST_QUIET_LOG'] ? Loog::NULL : Loog::REGULAR
  set :log, Loog::Tee.new(settings.log, Logger.new('target/log.txt')) if ENV['RACK_ENV'] == 'test'
  set :server_settings, timeout: 25
  set :zache, Zache.new(dirty: true)
  set :codec, GLogin::Codec.new(config['github']['encryption_secret'])
  if ENV['RACK_ENV'] == 'test'
    set :telepost, Telepost::Fake.new
  else
    set :telepost, Telepost.new(settings.config['telegram']['token'], chats: [settings.config['telegram']['channel']])
  end
  set :glogin, GLogin::Auth.new(
    config['github']['client_id'],
    config['github']['client_secret'],
    'https://www.codexia.org/github-callback'
  )
  if File.exist?('target/pgsql-config.yml')
    set :pgsql, Pgtk::Pool.new(
      Pgtk::Wire::Yaml.new(File.join(__dir__, 'target/pgsql-config.yml')),
      log: settings.log
    )
  else
    set :pgsql, Pgtk::Pool.new(
      Pgtk::Wire::Env.new('DATABASE_URL'),
      log: settings.log
    )
  end
  settings.pgsql.start(4)
end

get '/' do
  redirect '/inbox'
end

get '/welcome' do
  haml :welcome, layout: nil, locals: merged
end

get '/api' do
  haml :api, layout: :layout, locals: merged(
    title: '/api',
    token: the_author.token(settings.codec)
  )
end

def the_authors
  Xia::Authors.new(
    settings.pgsql,
    log: settings.log,
    telepost: settings.telepost
  )
end

def the_author
  redirect '/welcome' unless @locals[:author]
  require_relative 'objects/authors'
  return @locals[:the_author] if @locals[:the_author]
  @locals[:the_author] = Tacky.new(
    the_authors.named(@locals[:author][:login].downcase)
  )
end

def the_projects(a = the_author)
  AlterOut.new(
    Xia::Projects.new(
      settings.pgsql,
      a,
      log: settings.log,
      telepost: settings.telepost
    ),
    get: proc do |p|
      raise Xia::NotFound, "Project #{p.id} is not found" unless p.exists?
      p
    end
  )
end

def iri
  Iri.new(request.url)
end

require_relative 'front/front_misc.rb'
require_relative 'front/front_login.rb'
require_relative 'front/front_helpers.rb'
require_relative 'front/front_author.rb'
require_relative 'front/front_authors.rb'
require_relative 'front/front_project.rb'
require_relative 'front/front_projects.rb'
require_relative 'front/front_karma.rb'
require_relative 'front/front_payables.rb'
require_relative 'front/front_sql.rb'
require_relative 'front/front_terms.rb'
require_relative 'front/front_bots.rb'
