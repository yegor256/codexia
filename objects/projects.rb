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
require_relative 'project'

# Projects.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020 Yegor Bugayenko
# License:: MIT
class Xia::Projects
  def initialize(pgsql, author, log: Loog::NULL, telepost: Telepost::Fake.new)
    @pgsql = pgsql
    @author = author
    @log = log
    @telepost = telepost
  end

  def get(id)
    Xia::Project.new(@pgsql, @author, id, log: @log, telepost: @telepost)
  end

  def submit(platform, coordinates)
    raise Xia::Urror, 'Not enough karma to submit a project' if @author.karma.points.negative?
    raise Xia::Urror, 'You are submitting too fast' if quota.negative?
    raise Xia::Urror, 'Coordinates are wrong' unless %r{^[a-z0-9-]+/[a-z0-9-]+$}.match?(coordinates)
    raise Xia::Urror, 'The only possible platform now is "github"' unless platform == 'github'
    id = @pgsql.exec(
      'INSERT INTO project (platform, coordinates, author) VALUES ($1, $2, $3) RETURNING id',
      [platform, coordinates, @author.id]
    )[0]['id'].to_i
    project = get(id)
    project.badges.attach('newbie')
    @telepost.spam(
      "😍 New #{platform} project [`#{coordinates}`](https://www.codexia.org/p/#{id}) has been submitted",
      "by [@#{@author.login}](https://github.com/#{@author.login})"
    )
    project
  end

  def quota
    (@author.vip? ? 1000 : 5) - @pgsql.exec(
      'SELECT COUNT(*) FROM project WHERE created > NOW() - INTERVAL \'1 DAY\' AND author=$1',
      [@author.id]
    )[0]['count'].to_i
  end

  def recent(limit: 10)
    q = [
      'SELECT p.*, author.login, author.id AS author_id,',
      'ARRAY(SELECT text FROM badge WHERE project=p.id) as badges',
      'FROM project AS p',
      'JOIN author ON author.id=p.author',
      'WHERE p.deleted IS NULL',
      'ORDER BY p.created DESC',
      'LIMIT $1'
    ].join(' ')
    @pgsql.exec(q, [limit]).map do |r|
      {
        id: r['id'].to_i,
        coordinates: r['coordinates'],
        author: r['login'],
        author_id: r['author_id'].to_i,
        badges: r['badges'][1..-2].split(','),
        created: Time.parse(r['created'])
      }
    end
  end
end
