# frozen_string_literal: true

# Copyright (c) 2020-2023 Yegor Bugayenko
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
require 'redcarpet'
require 'securerandom'
require 'tacky'
require 'veil'
require_relative 'xia'
require_relative 'review'
require_relative 'rank'
require_relative 'bots'

# Reviews.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020-2023 Yegor Bugayenko
# License:: MIT
class Xia::Reviews
  # When such a review already exists and we can't post a new one.
  class DuplicateError < Xia::Urror; end

  def initialize(pgsql, project, log: Loog::NULL, telepost: Telepost::Fake.new)
    @pgsql = pgsql
    @project = project
    @log = log
    @telepost = telepost
  end

  def get(id)
    Xia::Review.new(@pgsql, @project, id, log: @log)
  end

  # A review with this hash already exists?
  def exists?(hash)
    !@pgsql.exec(
      'SELECT COUNT(*) FROM review WHERE project=$1 AND hash=$2',
      [@project.id, hash]
    )[0]['count'].to_i.zero?
  end

  def post(text, hash = SecureRandom.hex)
    Xia::Rank.new(@project.author).enter('reviews.post')
    Xia::Rank.new(@project.author).quota('review', 'post')
    unless @project.deleter.nil?
      raise Xia::Urror, "The project is already deleted by @#{@project.deleter.login}, can\'t review"
    end
    raise Xia::Urror, "The review is too short for us, just #{text.length}" if text.length < 30
    raise Xia::Urror, 'Hash can\'t be empty' if hash.empty?
    raise DuplicateError, 'A review with this hash already exists' if exists?(hash)
    id = @pgsql.exec(
      'INSERT INTO review (project, author, text, hash) VALUES ($1, $2, $3, $4) RETURNING id',
      [@project.id, @project.author.id, text, hash]
    )[0]['id'].to_i
    @project.unseen!
    unless Xia::Bots.new.is?(@project.author)
      @telepost.spam(
        "👍 New review no.#{id} has been posted for the project",
        "[#{@project.coordinates}](https://www.codexia.org/p/#{@project.id})",
        "by [@#{@project.author.login}](https://github.com/#{@project.author.login})"
      )
    end
    get(id)
  end

  def recent(limit: 10, offset: 0, show_deleted: false)
    carpet = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    q = [
      'SELECT r.*, author.login AS author_login, author.id AS author_id,',
      'deleter.id AS deleter_id, deleter.login AS deleter_login,',
      '(SELECT COUNT(*) FROM vote AS v WHERE v.review=r.id AND positive=true) AS up,',
      '(SELECT COUNT(*) FROM vote AS v WHERE v.review=r.id AND positive=false) AS down',
      'FROM review AS r',
      'JOIN author ON author.id=r.author',
      'LEFT JOIN author AS deleter ON deleter.id=r.deleter',
      'WHERE project=$1',
      show_deleted ? '' : ' AND r.deleter IS NULL',
      'ORDER BY r.created DESC',
      'LIMIT $2 OFFSET $3'
    ].join(' ')
    @pgsql.exec(q, [@project.id, limit, offset]).map do |r|
      Xia::Sieve.new(
        Veil.new(
          get(r['id'].to_i),
          text: r['text'],
          html: carpet.render(r['text']),
          up: r['up'].to_i,
          down: r['down'].to_i,
          deleter: r['deleter'].nil? ? nil : Xia::Sieve.new(
            Veil.new(
              Xia::Author.new(@pgsql, r['deleter_id'].to_i, log: @log, telepost: @telepost),
              id: r['deleter_id'].to_i,
              login: r['deleter_login']
            ),
            :id, :login
          ),
          created: Time.parse(r['created']),
          submitter: Xia::Sieve.new(
            Veil.new(
              Xia::Author.new(@pgsql, r['author_id'].to_i, log: @log, telepost: @telepost),
              id: r['author_id'].to_i,
              login: r['author_login']
            ),
            :id, :login
          )
        ),
        :id, :text, :html, :up, :down, :created, :deleter, :submitter
      )
    end
  end
end
