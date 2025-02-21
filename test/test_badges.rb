# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'threads'
require 'minitest/autorun'
require_relative 'test__helper'
require_relative '../objects/xia'
require_relative '../objects/authors'

class Xia::BadgesTest < Minitest::Test
  def test_attaches_badge
    author = Xia::Authors.new(t_pgsql).named('-test22')
    projects = author.projects
    project = projects.submit('github', "yegor256/takes#{rand(999)}")
    badges = project.badges
    text = 'jey'
    badge = badges.attach(text)
    assert_equal(2, badges.to_a.size)
    assert(badges.to_a.map(&:text).include?(text))
    assert(!badge.id.nil?)
    badge.detach
  end

  def test_attaches_badge_in_threads
    author = Xia::Authors.new(t_pgsql).named('-test099')
    projects = author.projects
    project = projects.submit('github', "yegor256/takes#{rand(999)}")
    badges = project.badges
    Threads.new(20).assert do
      badge = badges.attach('newbie')
      assert(!badge.id.nil?)
    rescue Xia::Badges::DuplicateError => e
      assert(!e.nil?)
    end
  end

  def test_promotes_and_degrades
    author = Xia::Authors.new(t_pgsql).named("test#{rand(999)}")
    author.karma.add(10_000, '0', 0)
    projects = author.projects
    project = projects.submit('github', "yegor256/cactoos#{rand(999)}")
    badges = project.badges
    badges.attach('L3')
    assert_equal(1, badges.to_a.size)
    assert_equal(3, badges.level)
    badges.attach('newbie')
    assert_equal(0, badges.level)
  end
end
