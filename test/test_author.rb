# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

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
