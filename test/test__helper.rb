# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

ENV['RACK_ENV'] = 'test'

require 'simplecov'
if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end
SimpleCov.start

require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]
Minitest.load :minitest_reporter

require 'yaml'
require 'minitest/autorun'
require 'pgtk/pool'
require 'loog'
module Minitest
  class Test
    def t_pgsql
      # rubocop:disable Style/ClassVars
      @@t_pgsql ||= Pgtk::Pool.new(
        Pgtk::Wire::Yaml.new(File.join(__dir__, '../target/pgsql-config.yml')),
        max: 4,
        log: ENV['TEST_QUIET_LOG'] ? Loog::NULL : Loog::VERBOSE
      ).start!
      # rubocop:enable Style/ClassVars
    end
  end
end
