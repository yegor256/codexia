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

class Xia::ReviewsTest < Minitest::Test
  def test_submits_review
    author = Xia::Authors.new(t_pgsql).named('-test-')
    projects = author.projects
    project = projects.submit('github', "yegor256/takes#{rand(999)}")
    reviews = project.reviews
    review = reviews.post('This is a test review good enough to be posted')
    assert(!review.id.nil?)
    assert(!reviews.recent.empty?)
  end

  def test_rejects_review_for_deleted_project
    author = Xia::Authors.new(t_pgsql).named('-test-')
    projects = author.projects
    project = projects.submit('github', "yegor256/takes#{rand(999)}")
    project.delete
    reviews = project.reviews
    assert_raises(Xia::Urror) do
      reviews.post('This is a test review good enough to be posted', '--')
    end
  end

  def test_fetches_only_right_reviews
    author = Xia::Authors.new(t_pgsql).named('-test-')
    projects = author.projects
    project = projects.submit('github', "yegor256/foo#{rand(999)}")
    project.reviews.post('This is a test review good enough to be posted')
    assert_equal(1, project.reviews.recent.size)
  end

  def test_rejects_duplicate_markers
    author = Xia::Authors.new(t_pgsql).named('-test-')
    projects = author.projects
    project = projects.submit('github', "yegor256/foo#{rand(999)}")
    text = 'This is a test review good enough to be posted'
    project.reviews.post(text, 'hash')
    assert_raises(Xia::Reviews::DuplicateError) do
      project.reviews.post(text + '.', 'hash')
    end
  end
end
