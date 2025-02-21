# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'zold/wts'
require_relative 'test__helper'
require_relative '../objects/xia'
require_relative '../objects/authors'

class Xia::RankTest < Minitest::Test
  def test_rank
    authors = Xia::Authors.new(t_pgsql)
    login = "test#{rand(999)}"
    author = authors.named(login)
    assert(Xia::Rank.new(author).ok?('projects.submit'))
  end

  def test_quota
    authors = Xia::Authors.new(t_pgsql)
    login = "test#{rand(999)}"
    author = authors.named(login)
    Xia::Rank.new(author).quota('project', 'submit')
    5.times do
      author.projects.submit('github', "yegor-1A.o/takes_#{rand(999)}")
    end
    assert_raises Xia::Urror do
      Xia::Rank.new(author).quota('project', 'submit')
    end
  end
end
