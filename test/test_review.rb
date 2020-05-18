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

class Xia::ReviewTest < Minitest::Test
  def test_votes_review
    author = Xia::Authors.new(t_pgsql).named('-test-')
    projects = author.projects
    project = projects.submit('github', "yegor256/takes#{rand(999)}")
    reviews = project.reviews
    review = reviews.post('This is a test review good enough to be posted')
    id = review.vote(true)
    assert(!id.nil?)
    assert_equal(id, review.vote(false))
  end

  def test_deletes_own_review
    author = Xia::Authors.new(t_pgsql).named('-test002')
    projects = author.projects
    project = projects.submit('github', "yegor256/takes#{rand(999)}")
    reviews = project.reviews
    review = reviews.post('This is a test review good enough to be posted')
    assert(!project.reviews.recent.empty?)
    assert(review.deleter.nil?)
    review.delete
    assert(project.reviews.recent.empty?)
    assert(!review.deleter.nil?)
    assert(!review.deleter.login.nil?)
  end

  def test_deletes_someones_review
    author = Xia::Authors.new(t_pgsql).named('-test09300')
    projects = author.projects
    project = projects.submit('github', "yegor256/takes#{rand(99_999)}")
    reviewer = Xia::Authors.new(t_pgsql).named('-test2286q')
    review = reviewer.projects.get(project.id).reviews.post(
      'This is a test review good enough to be posted'
    )
    project.reviews.get(review.id).delete
    assert(project.reviews.recent.empty?)
  end
end
