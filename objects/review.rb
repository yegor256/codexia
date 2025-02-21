# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'redcarpet'
require 'tacky'
require_relative 'xia'
require_relative 'rank'
require_relative 'bots'

# Review.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020-2025 Yegor Bugayenko
# License:: MIT
class Xia::Review
  attr_reader :id
  attr_reader :project

  def initialize(pgsql, project, id, log: Loog::NULL)
    @pgsql = pgsql
    @project = project
    @id = id
    @log = log
  end

  def created
    Time.parse(column(:created))
  end

  def deleter
    d = column(:deleter)
    return d if d.nil?
    Xia::Author.new(@pgsql, d.to_i, log: @log, telepost: @telepost)
  end

  def submitter
    Xia::Author.new(@pgsql, column(:author).to_i, log: @log, telepost: @telepost)
  end

  def up
    @pgsql.exec('SELECT COUNT(*) FROM vote WHERE review=$1 AND positive=$2', [@id, true])[0]['count'].to_i
  end

  def down
    @pgsql.exec('SELECT COUNT(*) FROM vote WHERE review=$1 AND positive=$2', [@id, false])[0]['count'].to_i
  end

  def text
    column(:text)
  end

  def html
    carpet = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    carpet.render(text)
  end

  def delete
    if submitter.id == @project.author.id
      Xia::Rank.new(@project.author).enter('reviews.delete-own')
    else
      Xia::Rank.new(@project.author).enter('reviews.delete')
    end
    @pgsql.exec(
      'UPDATE review SET deleter=$1 WHERE id=$2',
      [@project.author.id, @id]
    )
    @project.unseen!
  end

  def vote(up)
    Xia::Rank.new(@project.author).enter('reviews.upvote') if up
    Xia::Rank.new(@project.author).enter('reviews.downvote') unless up
    Xia::Rank.new(@project.author).quota('vote', 'vote')
    raise Xia::Urror, "The review is already deleted by @#{deleter.login}, can\'t vote" if deleter
    raise Xia::Urror, 'The project is deleted, can\'t vote' if @project.deleter
    @pgsql.exec(
      [
        'INSERT INTO vote (review, author, positive)',
        'VALUES ($1, $2, $3)',
        'ON CONFLICT (review, author) DO UPDATE SET positive=$3',
        'RETURNING id'
      ].join(' '),
      [@id, @project.author.id, up]
    )[0]['id'].to_i
  end

  private

  def column(name)
    r = @pgsql.exec("SELECT #{name} FROM review WHERE id=$1", [@id])[0]
    raise Xia::Urror, "Review ##{@id} not found in the database" if r.nil?
    r[name.to_s]
  end
end
