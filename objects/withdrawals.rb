# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'zold/wts'
require_relative 'xia'
require_relative 'rank'

# Withdrawals.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020-2025 Yegor Bugayenko
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
