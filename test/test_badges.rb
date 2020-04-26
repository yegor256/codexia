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
