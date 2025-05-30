# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'telepost'
require_relative 'xia'

# Meta.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020-2025 Yegor Bugayenko
# License:: MIT
class Xia::Meta
  def initialize(pgsql, project, log: Loog::NULL, telepost: Telepost::Fake.new)
    @pgsql = pgsql
    @project = project
    @log = log
    @telepost = telepost
  end

  def exists?(key)
    raise Xia::Urror, 'The key can\'t be empty' if key.empty?
    raise Xia::Urror, 'The key may include letters, numbers, and dashes only' unless /^[a-zA-Z0-9-]+$/.match?(key)
    a, k = key.split(':', 2)
    !@pgsql.exec(
      'SELECT COUNT(*) FROM meta JOIN author ON author.id=meta.author WHERE project=$1 AND login=$2 AND key=$3',
      [@project.id, a, k]
    )[0]['count'].to_i.zero?
  end

  def set(key, value)
    raise Xia::Urror, 'The value can\'t be empty' if value.empty?
    raise Xia::Urror, 'The key can\'t be empty' if key.empty?
    raise Xia::Urror, 'The key may include letters, numbers, and dashes only' unless /^[a-zA-Z0-9-]+$/.match?(key)
    raise Xia::Urror, 'The value is too large (over 256)' if value.length > 256
    exists = exists?(key)
    id = @pgsql.exec(
      [
        'INSERT INTO meta (project, author, key, value) VALUES ($1, $2, $3, $4)',
        'ON CONFLICT (project, author, key) DO UPDATE SET value = $4 RETURNING id'
      ].join(' '),
      [@project.id, @project.author.id, key, value]
    )[0]['id'].to_i
    unless Xia::Bots.new.is?(@project.author)
      if exists
        @telepost.spam(
          "The meta \"`#{key}`\" re-set for the project",
          "[#{@project.coordinates}](https://www.codexia.org/p/#{@project.id})",
          "by [@#{@project.author.login}](https://github.com/#{@project.author.login})"
        )
      else
        @telepost.spam(
          "A new meta \"`#{key}`\" set for the project",
          "[#{@project.coordinates}](https://www.codexia.org/p/#{@project.id})",
          "by [@#{@project.author.login}](https://github.com/#{@project.author.login})"
        )
      end
    end
    id
  end

  def value(key)
    a, k = key.split(':', 2)
    row = @pgsql.exec(
      'SELECT value FROM meta JOIN author ON author.id=meta.author WHERE project=$1 AND login=$2 AND key=$3',
      [@project.id, a, k]
    )[0]
    raise Xia::Urror, "The key #{key.inspect} is not found" if row.nil?
    row['value']
  end

  def to_a
    q = [
      'SELECT m.*, author.login AS login',
      'FROM meta AS m',
      'JOIN author ON author.id=m.author',
      'WHERE project=$1'
    ].join(' ')
    @pgsql.exec(q, [@project.id]).map do |r|
      {
        id: r['id'].to_i,
        author: r['login'],
        key: "#{r['login']}:#{r['key']}",
        value: r['value'],
        updated: Time.parse(r['updated'])
      }
    end
  end
end
