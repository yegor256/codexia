# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'test__helper'
require_relative '../objects/xia'
require_relative '../objects/authors'

class Xia::ProjectTest < Minitest::Test
  def test_submits_project
    author = Xia::Authors.new(t_pgsql).named('-test-')
    projects = author.projects
    project = projects.submit('github', "yegor256/takes#{rand(999)}")
    project.delete
  end

  def test_seen_unseen
    author = Xia::Authors.new(t_pgsql).named('-test-')
    projects = author.projects
    project = projects.submit('github', 'test/hey009')
    project.seen!
    project.seen!
    project.unseen!
    project.unseen!
  end

  def test_seen_unseen_by_friend
    author = Xia::Authors.new(t_pgsql).named('-test955-first')
    p1 = author.projects.submit('github', 'test/hey938533')
    p1.seen!
    friend = Xia::Authors.new(t_pgsql).named('-test955-second')
    p2 = friend.projects.get(p1.id)
    p2.seen!
  end
end
