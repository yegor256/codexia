# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

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
