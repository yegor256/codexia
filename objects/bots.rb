# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

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
