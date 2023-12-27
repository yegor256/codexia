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

ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start
if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

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
        log: ENV['TEST_QUIET_LOG'] ? Loog::NULL : Loog::VERBOSE
      ).start(4)
      # rubocop:enable Style/ClassVars
    end
  end
end
