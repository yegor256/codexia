# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

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

  def test_fetches_deleted_reviews
    author = Xia::Authors.new(t_pgsql).named('-test-')
    projects = author.projects
    project = projects.submit('github', "yegor256/foo#{rand(999)}")
    review = project.reviews.post('This is a test review good enough to be posted')
    review.delete
    assert(!project.reviews.recent(show_deleted: true)[0].deleter.login.nil?)
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
