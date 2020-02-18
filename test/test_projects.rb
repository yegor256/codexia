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
require_relative 'test__helper'
require_relative '../objects/xia'
require_relative '../objects/authors'
require_relative '../objects/projects'

class Xia::ProjectsTest < Minitest::Test
  def test_submits_project
    author = Xia::Authors.new(t_pgsql).named('yegor256')
    projects = author.projects
    project = projects.submit('github', "yegor-1/takes_#{rand(999)}")
    assert(!project.id.nil?)
    assert(!projects.recent.empty?)
  end

  def test_adds_badges_and_fetches_them
    author = Xia::Authors.new(t_pgsql).named('yegor256')
    projects = author.projects
    project = projects.submit('github', "yegor256/takes#{rand(999)}")
    badge = 'hello'
    project.badges.attach(badge)
    project.badges.attach('something')
    assert(projects.recent[0][:badges].is_a?(Array))
    assert(projects.recent[0][:badges].include?(badge))
  end
end
