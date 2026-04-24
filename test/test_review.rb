# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

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
    refute_nil(id)
    assert_equal(id, review.vote(false))
  end

  def test_deletes_own_review
    author = Xia::Authors.new(t_pgsql).named('-test002')
    projects = author.projects
    project = projects.submit('github', "yegor256/takes#{rand(999)}")
    reviews = project.reviews
    review = reviews.post('This is a test review good enough to be posted')
    refute_empty(project.reviews.recent)
    assert_nil(review.deleter)
    review.delete
    assert_empty(project.reviews.recent)
    refute_nil(review.deleter)
    refute_nil(review.deleter.login)
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
    assert_empty(project.reviews.recent)
  end
end
