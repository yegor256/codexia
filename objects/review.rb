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

  def delete
    raise Xia::Urror, 'Not enough karma to delete a review' if @project.author.karma.points < 500
    @pgsql.exec(
      'UPDATE review SET deleted = $2 WHERE id=$1',
      [@id, "Deleted by @#{@project.author.login} on #{Time.now.utc.iso8601}"]
    )
  end

  def vote(up)
    raise Xia::Urror, 'Not enough karma to upvote a review' if @project.author.karma.points < 100
    raise Xia::Urror, 'Not enough karma to downvote a review' if !up && @project.author.karma.points < 200
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
end
