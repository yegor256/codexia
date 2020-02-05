# frozen_string_literal: true

# Copyright (c) 2020 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

STDOUT.sync = true

require 'glogin'
require 'glogin/codec'
require 'haml'
require 'iri'
require 'loog'
require 'json'
require 'pgtk'
require 'pgtk/pool'
require 'raven'
require 'relative_time'
require 'sinatra'
require 'sinatra/cookies'
require 'telebot'
require 'time'
require 'yaml'
require_relative 'objects/urror'
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
    'sentry' => ''
  }
  config = YAML.safe_load(File.open(File.join(File.dirname(__FILE__), 'config.yml'))) unless ENV['RACK_ENV'] == 'test'
  if ENV['RACK_ENV'] != 'test'
    Raven.configure do |c|
      c.dsn = config['sentry']
      c.release = Xia::VERSION
    end
  end
  disable :show_exceptions
  disable :raise_errors
  enable :logging
  set :bind, '0.0.0.0'
  set :server, :thin
  set :dump_errors, ENV['RACK_ENV'] == 'test'
  set :config, config
  set :logging, true
  set :log, Loog::REGULAR
  set :server_settings, timeout: 25
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
  redirect '/recent'
end

get '/welcome' do
  haml :welcome, layout: nil, locals: merged
end

get '/recent' do
  haml :recent, layout: :layout, locals: merged(
    title: '/recent',
    list: the_author.projects.recent(limit: 25)
  )
end

get '/submit' do
  haml :submit, layout: :layout, locals: merged(
    title: '/submit'
  )
end

post '/do-submit' do
  project = the_author.projects.submit(params[:platform], params[:coordinates])
  flash('/recent', "A new project #{project.id} has been submitted!")
end

get '/terms' do
  haml :terms, layout: :layout, locals: merged(
    title: '/terms',
    legend: the_author.karma.legend
  )
end

get '/sql' do
  raise Xia::Urror, 'You are not allowed to see this' unless the_author.vip?
  query = params[:query] || 'SELECT * FROM author LIMIT 16'
  haml :sql, layout: :layout, locals: merged(
    title: '/sql',
    query: query,
    result: settings.pgsql.exec(query)
  )
end

def the_author
  redirect '/welcome' unless @locals[:author]
  require_relative 'objects/authors'
  Xia::Authors.new(settings.pgsql, log: settings.log).named(@locals[:author][:login].downcase)
end

def iri
  Iri.new(request.url)
end

require_relative 'front/front_misc.rb'
require_relative 'front/front_login.rb'
require_relative 'front/front_helpers.rb'
require_relative 'front/front_project.rb'
require_relative 'front/front_karma.rb'
