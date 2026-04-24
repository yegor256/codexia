# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'test__helper'
require_relative '../objects/xia'
require_relative '../objects/authors'
require_relative '../objects/projects'

class Xia::KarmaTest < Minitest::Test
  def test_list_withdrawals
    author = Xia::Authors.new(t_pgsql).named('-yegor256')
    withdrawals = author.withdrawals
    refute_nil(withdrawals.recent)
    refute_nil(withdrawals.total)
  end
end
