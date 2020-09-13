# frozen_string_literal: true

# Copyright (c) 2020 Yegor Bugayenko
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
require 'zold/wts'
require_relative 'xia'
require_relative 'rank'

# Withdrawals.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020 Yegor Bugayenko
# License:: MIT
class Xia::Withdrawals
  def initialize(pgsql, author, log: Loog::NULL, telepost: Telepost::Fake.new)
    @pgsql = pgsql
    @author = author
    @log = log
    @telepost = telepost
  end

  # +points+ is the amount of Karma points to pay. Each Karma point will
  # be converted to 1 USD.
  def pay(wallet, points, wts, keygap)
    Xia::Rank.new(@author).enter('withdraw', safe: true)
    rate = wts.usd_rate
    zld = (points / rate).round(4).to_f
    wts.wait(wts.pull)
    job = wts.pay(keygap, wallet, zld, "#{points} codexia karma points")
    wts.wait(job)
    @author.karma.add(points, wallet, Zold::Amount.new(zld: zld).to_i)
    @telepost.spam(
      "New withdrawal for #{points} points (#{zld} ZLD) has been made",
      "by [@#{@author.login}](https://www.codexia.org/a/#{@author.login})"
    )
  end

  # How many points were taken home already
  def total
    @pgsql.exec('SELECT SUM(points) FROM withdrawal WHERE author=$1', [@author.id])[0]['sum'].to_i
  end

  def recent(limit: 10)
    q = [
      'SELECT *',
      'FROM withdrawal',
      'WHERE author=$1',
      'ORDER BY created DESC',
      'LIMIT $2'
    ].join(' ')
    @pgsql.exec(q, [@author.id, limit]).map do |r|
      {
        id: r['id'].to_i,
        zld: Zold::Amount.new(zents: r['zents'].to_i),
        points: r['points'].to_i,
        wallet: r['wallet'],
        created: Time.parse(r['created'])
      }
    end
  end
end
