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

require_relative 'xia'
require_relative 'rank'

# Review.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020 Yegor Bugayenko
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

  def deleted
    row[:deleted]
  end

  def delete
    Xia::Rank.new(@project.author).enter('reviews.delete')
    @pgsql.exec(
      'UPDATE review SET deleted = $2 WHERE id=$1',
      [@id, "Deleted by @#{@project.author.login} on #{Time.now.utc.iso8601}"]
    )
  end

  def quota
    return 1 if @project.author.vip?
    max = 10
    max = 100 if @project.author.bot?
    max - @pgsql.exec(
      'SELECT COUNT(*) FROM vote WHERE created > NOW() - INTERVAL \'1 DAY\' AND author=$1',
      [@project.author.id]
    )[0]['count'].to_i
  end

  def vote(up)
    Xia::Rank.new(@project.author).enter('reviews.upvote') if up
    Xia::Rank.new(@project.author).enter('reviews.downvote') unless up
    raise Xia::Urror, 'You are voting too fast' if quota.negative?
    raise Xia::Urror, 'It is already deleted, can\'t vote' if deleted
    raise Xia::Urror, 'The project is deleted, can\'t vote' if @project.deleted
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

  def row
    r = @pgsql.exec(
      'SELECT * FROM review WHERE id=$1',
      [@id]
    )[0]
    raise Xia::Urror, "Project ##{@id} not found in the database" if r.nil?
    {
      id: r['id'].to_i,
      platform: r['platform'],
      coordinates: r['coordinates'],
      author: r['author'].to_i,
      deleted: r['deleted'],
      created: Time.parse(r['created'])
    }
  end
end
