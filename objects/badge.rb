# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require_relative 'xia'
require_relative 'rank'

# Badges.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020-2025 Yegor Bugayenko
# License:: MIT
class Xia::Badge
  attr_reader :id

  def initialize(pgsql, project, id, log: Loog::NULL)
    @pgsql = pgsql
    @project = project
    @id = id
    @log = log
  end

  def text
    @pgsql.exec('SELECT * FROM badge WHERE id=$1', [@id])[0]['text']
  end

  def detach
    Xia::Rank.new(@project.author).enter('badges.detach')
    raise Xia::Urror, 'Can\'t delete the last badge' if @project.badges.to_a.size < 2
    @project.unseen!
    @pgsql.exec('DELETE FROM badge WHERE id=$1', [@id])
  end
end
