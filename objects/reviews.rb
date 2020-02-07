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
require_relative 'xia'
require_relative 'review'

# Reviews.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020 Yegor Bugayenko
# License:: MIT
class Xia::Reviews
  def initialize(pgsql, project, log: Loog::NULL, telepost: Telepost::Fake.new)
    @pgsql = pgsql
    @project = project
    @log = log
    @telepost = telepost
  end

  def get(id)
    Xia::Review.new(@pgsql, @project, id, log: @log)
  end

  def post(text)
    raise Xia::Urror, 'Not enough karma to post a review' if @project.author.karma.points.negative?
    raise Xia::Urror, 'The review is too short' if text.length < 60 && @project.author.login != '-test-'
    raise Xia::Urror, 'You are reviewing too fast' if quota.negative?
    id = @pgsql.exec(
      'INSERT INTO review (project, author, text) VALUES ($1, $2, $3) RETURNING id',
      [@project.id, @project.author.id, text]
    )[0]['id'].to_i
    @telepost.spam(
      "New review has been posted for the project `#{@project.coordinates}`",
      "by [@#{@project.author.login}](https://github.com/#{@project.author.login})"
    )
    get(id)
  end

  def quota
    (@project.author.vip? ? 1000 : 5) - @pgsql.exec(
      'SELECT COUNT(*) FROM review WHERE created > NOW() - INTERVAL \'1 DAY\' AND author=$1',
      [@project.author.id]
    )[0]['count'].to_i
  end

  def recent(limit: 10)
    q = [
      'SELECT r.*, author.login, author.id AS author_id,',
      '(SELECT COUNT(*) FROM vote AS v WHERE v.review=r.id AND positive=true) AS up,',
      '(SELECT COUNT(*) FROM vote AS v WHERE v.review=r.id AND positive=false) AS down',
      'FROM review AS r',
      'JOIN author ON author.id=r.author',
      'WHERE project=$1 AND r.deleted IS NULL',
      'ORDER BY r.created DESC',
      'LIMIT $2'
    ].join(' ')
    @pgsql.exec(q, [@project.id, limit]).map do |r|
      {
        id: r['id'].to_i,
        text: r['text'],
        author: r['login'],
        author_id: r['author_id'].to_i,
        up: r['up'].to_i,
        down: r['down'].to_i,
        created: Time.parse(r['created'])
      }
    end
  end
end
