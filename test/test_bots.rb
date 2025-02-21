# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'test__helper'
require_relative '../objects/xia'
require_relative '../objects/bots'
require_relative '../objects/authors'

class Xia::BotsTest < Minitest::Test
  def test_fetches_all_bots
    authors = Xia::Authors.new(t_pgsql)
    authors.named('cdxbot')
    bots = Xia::Bots.new(t_pgsql)
    assert(!bots.authors.empty?)
    bot = bots.authors.first
    assert(!bot.login.nil?)
  end
end
