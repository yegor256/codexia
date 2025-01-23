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

require 'loog'
require 'telepost'
require 'unpiercable'
require_relative 'xia'
require_relative 'author'

# Authors.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020-2025 Yegor Bugayenko
# License:: MIT
class Xia::Authors
  def initialize(pgsql, log: Loog::NULL, telepost: Telepost::Fake.new)
    @pgsql = pgsql
    @log = log
    @telepost = telepost
  end

  def named(login)
    @pgsql.exec('INSERT INTO author (login) VALUES ($1) ON CONFLICT DO NOTHING', [login])
    id = @pgsql.exec('SELECT id FROM author WHERE login=$1', [login])[0]['id'].to_i
    Xia::Author.new(@pgsql, id, log: @log, telepost: @telepost)
  end

  def best(limit: 25)
    @pgsql.exec(
      [
        'SELECT author.id, author.login, SUM(withdrawal.points) AS points FROM author',
        'JOIN withdrawal ON author.id=withdrawal.author',
        'GROUP BY author.id',
        'ORDER BY points DESC',
        'LIMIT $1'
      ].join(' '),
      [limit]
    ).map do |r|
      Unpiercable.new(
        Xia::Author.new(@pgsql, r['id'].to_i, log: @log, telepost: @telepost),
        login: r['login'],
        points: r['points'].to_i
      )
    end
  end
end
