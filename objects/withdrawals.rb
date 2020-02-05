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

# Withdrawals.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020 Yegor Bugayenko
# License:: MIT
class Xia::Withdrawals
  def initialize(pgsql, author, log: Loog::NULL)
    @pgsql = pgsql
    @author = author
    @log = log
  end

  # +points+ is the amount of Karma points to pay. Each Karma point will
  # be converted to 1 USD.
  def pay(wallet, points, wts, keygap)
    raise Xia::Urror, 'Not enough karma to pay that much' if @author.karma.points(safe: true) < points
    rate = wts.usd_rate
    zld = (points / rate).round(4)
    wts.wait(wts.pull)
    job = wts.pay(keygap, wallet, zld, "#{points} codexia karma points")
    wts.wait(job)
    @pgsql.exec(
      'INSERT INTO withdrawal (author, wallet, points, zents) VALUES ($1, $2, $3, $4) RETURNING id',
      [@author.id, wallet, points, Zold::Amount.new(zld: zld).to_i]
    )[0]['id'].to_i
  end

  def recent(limit: 10)
    q = [
      'SELECT *',
      'FROM withdrawal',
      'ORDER BY created DESC',
      'LIMIT $1'
    ].join(' ')
    @pgsql.exec(q, [limit]).map do |r|
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
