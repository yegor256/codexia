# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require_relative 'xia'
require_relative 'urror'
require_relative 'projects'
require_relative 'withdrawals'
require_relative 'karma'

# One author.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020-2025 Yegor Bugayenko
# License:: MIT
class Xia::Author
  attr_reader :id

  def initialize(pgsql, id, log: Loog::NULL, telepost: Telepost::Fake.new)
    @pgsql = pgsql
    @id = id
    @log = log
    @telepost = telepost
  end

  def vip?
    return true if login.start_with?('-')
    ['yegor256'].include?(login)
  end

  def login
    column(:login)
  end

  def karma
    Xia::Karma.new(@pgsql, self, log: @log)
  end

  def projects
    Xia::Projects.new(@pgsql, self, log: @log, telepost: @telepost)
  end

  def withdrawals
    Xia::Withdrawals.new(@pgsql, self, log: @log, telepost: @telepost)
  end

  def token(codec)
    loop do
      t = codec.encrypt(login)
      return t if t.length == 44 || t == login
    end
  end

  def footprint(entity)
    @pgsql.exec(
      "SELECT COUNT(*) FROM #{entity} WHERE created > NOW() - INTERVAL '1 DAY' AND author=$1",
      [@id]
    )[0]['count'].to_i
  end

  private

  def column(name)
    row = @pgsql.exec("SELECT #{name} FROM author WHERE id=$1", [@id])[0]
    raise Xia::Urror, "Author ##{@id} not found in the database" if row.nil?
    row[name.to_s]
  end
end
