# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'test__helper'
require_relative '../objects/xia'
require_relative '../objects/authors'

class Xia::MetaTest < Minitest::Test
  def test_set_and_read
    author = Xia::Authors.new(t_pgsql).named('-test-')
    projects = author.projects
    project = projects.submit('github', "yegor256/takes#{rand(999)}")
    meta = project.meta
    id = meta.set('ABC', 'works?')
    assert(!id.nil?)
    assert_equal(id, meta.set('ABC', 'second'))
    assert('second', meta.value('-test-:ABC'))
  end
end
