# frozen_string_literal: true

# Copyright (c) 2020-2025 Yegor Bugayenko
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

require 'tacky'
require_relative 'xia'
require_relative 'author'

# Bots.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020-2025 Yegor Bugayenko
# License:: MIT
class Xia::Bots
  # List of all of them
  ALL = ['cdxbot', 'iakunin-codexia-bot', 'codexia-hunter'].freeze

  def initialize(pgsql = nil, log: Loog::NULL, telepost: Telepost::Fake.new)
    @pgsql = pgsql
    @log = log
    @telepost = telepost
  end

  def is?(author)
    login = author.login
    return true if login.start_with?('-')
    ALL.include?(login)
  end

  def authors
    q = "SELECT id FROM author WHERE #{(1..ALL.count).map { |i| "login=$#{i}" }.join(' OR ')}"
    @pgsql.exec(q, ALL).map do |r|
      Xia::Author.new(@pgsql, r['id'].to_i, log: @log, telepost: @telepost)
    end
  end
end
