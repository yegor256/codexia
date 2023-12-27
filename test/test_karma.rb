# frozen_string_literal: true

# Copyright (c) 2020-2023 Yegor Bugayenko
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
require 'zold/wts'
require_relative 'test__helper'
require_relative '../objects/xia'
require_relative '../objects/authors'

class Xia::KarmaTest < Minitest::Test
  def test_karma
    authors = Xia::Authors.new(t_pgsql)
    login = "test#{rand(999)}"
    author = authors.named(login)
    project = author.projects.submit('github', "yegor256/takes#{rand(999)}")
    reviews = project.reviews
    reviews.post('This is a test review good enough to be posted')
    karma = authors.named(login).karma.points
    assert(karma.positive?, "The karma is #{karma}")
    assert(!authors.named(login).karma.points(safe: true).nil?)
  end

  def test_validity_of_points
    authors = Xia::Authors.new(t_pgsql)
    author = authors.named("test#{rand(999)}")
    author.karma.legend.each do |k|
      assert(k[:points].keys.any? { |t| t.to_s == '2000-01-01' }, "#{k[:terms]} is broken")
      assert(k[:bot].keys.any? { |t| t.to_s == '2000-01-01' }, "#{k[:terms]} is broken")
    end
  end

  def test_list_recent
    authors = Xia::Authors.new(t_pgsql)
    login = '-test-'
    author = authors.named(login)
    author.projects.submit('github', "yegor256/takes#{rand(999)}")
    assert(!author.karma.recent.empty?)
  end

  def test_takes_withdrawals_into_account
    authors = Xia::Authors.new(t_pgsql)
    login = '-test-'
    author = authors.named(login)
    author.projects.submit('github', "yegor256/takes#{rand(999)}")
    before = author.karma.points
    wts = Zold::WTS::Fake.new
    author.withdrawals.pay('0000111122223333', 1, wts, 'keygap')
    assert(author.karma.points != before)
    assert(author.karma.points(safe: true) != before)
  end
end
