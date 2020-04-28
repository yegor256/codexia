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
require 'tacky'
require_relative 'test__helper'
require_relative '../objects/xia'
require_relative '../objects/authors'

class Xia::AuthorTest < Minitest::Test
  def test_fetches_login
    authors = Xia::Authors.new(t_pgsql)
    login = 'hello'
    author = Tacky.new(authors.named(login))
    assert(author.login.is_a?(String), "Type is #{author.login.class.name}")
    assert_equal(login, author.login)
  end

  def test_updates_author
    authors = Xia::Authors.new(t_pgsql)
    author = authors.named('-test-')
    assert(!author.id.nil?)
  end

  def test_generates_token
    authors = Xia::Authors.new(t_pgsql)
    author = authors.named('-te')
    codec = GLogin::Codec.new('the-secret')
    assert_equal(44, author.token(codec).length)
  end
end
