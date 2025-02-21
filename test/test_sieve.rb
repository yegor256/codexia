# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'json'
require_relative 'test__helper'
require_relative '../objects/sieve'

class Xia::SieveTest < Minitest::Test
  def test_simple
    obj = Object.new
    def obj.data
      123
    end
    foo = Xia::Sieve.new(obj, :data)
    assert_equal(123, JSON.parse(foo.to_json)['data'])
  end

  def test_array
    foo = Xia::Sieve.new([1, 2, 3], :to_a)
    assert_equal(3, JSON.parse(foo.to_json).count)
  end
end
