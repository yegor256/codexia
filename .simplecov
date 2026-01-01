# encoding: utf-8
#
# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

if Gem.win_platform? then
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter
  ]
  SimpleCov.start do
    add_filter "/test/"
    add_filter "/features/"
  end
else
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [SimpleCov::Formatter::HTMLFormatter]
  )
  SimpleCov.start do
    add_filter "/test/"
    add_filter "/features/"
    #minimum_coverage 100
  end
end
