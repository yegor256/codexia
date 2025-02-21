# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'test__helper'
require_relative '../objects/xia'
require_relative '../objects/authors'

class Xia::AuthorsTest < Minitest::Test
  def test_updates_author
    authors = Xia::Authors.new(t_pgsql)
    login = '-test-'
    author = authors.named(login)
    assert(!author.id.nil?)
    assert_equal(author.id, authors.named(login).id)
  end
end
