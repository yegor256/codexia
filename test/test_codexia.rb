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

require 'minitest/autorun'
require 'rack/test'
require 'iri'
require_relative 'test__helper'
require_relative '../codexia'
require_relative '../objects/xia'

module Rack
  module Test
    class Session
      def default_env
        { 'REMOTE_ADDR' => '127.0.0.1', 'HTTPS' => 'on' }.merge(headers_for_env)
      end
    end
  end
end

class Xia::AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_renders_pages
    pages = [
      '/version',
      '/robots.txt',
      '/welcome',
      '/js/smth.js'
    ]
    pages.each do |p|
      get(p)
      assert(last_response.ok?, last_response.body)
    end
  end

  def test_not_found
    ['/unknown_path', '/js/x/y/z/not-found.js', '/css/a/b/c/not-found.css'].each do |p|
      get(p)
      assert_equal(404, last_response.status, last_response.body)
      assert_equal('text/html;charset=utf-8', last_response.content_type)
    end
  end

  def test_200_user_pages
    name = '-test'
    login(name)
    pages = [
      '/recent',
      '/recent?badges=newbie',
      '/inbox',
      '/karma',
      '/karma.csv',
      '/karma.json',
      '/payables?a=-test',
      '/a/-test',
      '/submit',
      '/authors',
      '/terms',
      '/bots',
      '/sql',
      '/sql?query=SELECT%20%2A%20FROM%20author',
      '/api'
    ]
    pages.each do |p|
      get(p)
      assert_equal(200, last_response.status, "#{p} fails: #{last_response.body.inspect}")
    end
  end

  def test_404_user_pages
    name = '-t39432432'
    login(name)
    pages = [
      '/p/47483',
      '/something-else'
    ]
    pages.each do |p|
      get(p)
      assert_equal(404, last_response.status, "#{p} fails: #{last_response.body.inspect}")
    end
  end

  def test_submits_wrong_coordinates
    login('-tester5')
    post(Iri.new('/submit').add(platform: 'github', coordinates: '-').to_s, nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
    assert_equal(303, last_response.status, "#{p} fails: #{last_response.body.inspect}")
  end

  def test_api_fetch_json
    login('-tester4')
    id = post_project('tt/ttt')
    post("/p/#{id}/post?text=hello", nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
    get('/recent.json', nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
    assert_equal(200, last_response.status, "#{p} fails: #{last_response.body.inspect}")
    json = JSON.parse(last_response.body)[0]
    assert(json.is_a?(Hash), "No projects in the JSON response: #{last_response.body.inspect}")
    assert(json['id'].is_a?(Integer), 'ID is not present')
    assert(json['submitter']['id'].is_a?(Integer))
    assert(json['deleter'].nil?)
    assert(json['badges'].is_a?(Array))
    assert_equal('newbie', json['badges'][0]['text'])
    assert(json['created'].is_a?(String))
    get("/p/#{id}.json", nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
    assert_equal(200, last_response.status, "#{p} fails: #{last_response.body.inspect}")
    json = JSON.parse(last_response.body)
    assert(json['id'].is_a?(Integer))
    assert(json['submitter']['id'].is_a?(Integer))
    assert(json['deleter'].nil?)
    assert(json['badges'].is_a?(Array))
  end

  def test_api_post_review
    login('-tester1')
    name = 'abc/ddd'
    id = post_project(name)
    assert_equal(post_project(name), id)
    text = 'This is a long enough review to pass all possible checks inside'
    uri = Iri.new("/p/#{id}/post").add(text: text, hash: 123).to_s
    post(uri, nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
    assert_equal(302, last_response.status, "#{p} fails: #{last_response.body.inspect}")
    post(uri, nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
    assert_equal(302, last_response.status, "#{p} fails: #{last_response.body.inspect}")
  end

  def test_attach_detach_badge
    login('-tester2')
    id = post_project('abc/my-badges')
    post("/p/#{id}/attach?text=thebadge", nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
    assert_equal(302, last_response.status, "#{p} fails: #{last_response.body.inspect}")
    post("/p/#{id}/attach?text=another", nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
    assert_equal(302, last_response.status, "#{p} fails: #{last_response.body.inspect}")
    get("/p/#{id}/badges.json", nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
    assert_equal(200, last_response.status, "#{p} fails: #{last_response.body.inspect}")
    json = JSON.parse(last_response.body)
    assert(json.is_a?(Array), json.to_s)
    assert(json.length > 1, json.to_s)
    badge = json[0]['id'].to_i
    get("/p/#{id}/detach/#{badge}", nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
    assert_equal(302, last_response.status, "can't detach #{badge}: #{last_response.body.inspect}")
  end

  def test_meta
    login('-tester3')
    id = post_project('hey/def')
    post("/p/#{id}/meta?key=test&value=22", nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
    assert_equal(302, last_response.status, "#{p} fails: #{last_response.body.inspect}")
    get("/p/#{id}/meta?key=-test-:test", nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
    assert_equal(200, last_response.status, "#{p} fails: #{last_response.body.inspect}")
  end

  private

  def login(name)
    set_cookie('glogin=' + name)
  end

  # Post a new project and return its ID
  def post_project(name)
    post(Iri.new('/submit').add(platform: 'github', coordinates: name).to_s, nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
    assert_equal(302, last_response.status, "#{p} fails: #{last_response.body.inspect}")
    id = last_response.header['Location'].gsub(%r{^.*/p/(\d+)$}, '\1')
    ["/p/#{id}", "/p/#{id}.json", "/p/#{id}/reviews.json"].each do |p|
      get(p, nil, 'HTTP_X_CODEXIA_TOKEN' => '-test-')
      assert_equal(200, last_response.status, "#{p} fails: #{last_response.body.inspect}")
    end
    id
  end
end
