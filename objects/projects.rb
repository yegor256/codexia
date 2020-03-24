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
require_relative 'rank'

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
    Xia::Rank.new(@author).enter('projects.submit')
    raise Xia::Urror, 'You are submitting too fast' if quota.negative?
    unless %r{^[A-Za-z0-9\-\.]+/[A-Za-z0-9\-_\.]+$}.match?(coordinates)
      raise Xia::Urror, "Coordinates #{coordinates.inspect} are wrong"
    end
    raise Xia::Urror, 'The only possible platform now is "github"' unless platform == 'github'
    row = @pgsql.exec(
      'SELECT id FROM project WHERE platform=$1 AND coordinates=$2',
      [platform, coordinates]
    )[0]
    return get(row['id'].to_i) unless row.nil?
    id = @pgsql.exec(
      'INSERT INTO project (platform, coordinates, author) VALUES ($1, $2, $3) RETURNING id',
      [platform, coordinates, @author.id]
    )[0]['id'].to_i
    project = get(id)
    project.badges.attach('newbie')
    @telepost.spam(
      "😍 New #{platform} project [#{coordinates}](https://www.codexia.org/p/#{id}) has been submitted",
      "by [@#{@author.login}](https://github.com/#{@author.login})"
    )
    project
  end

  def quota
    return 1 if @author.vip?
    max = 5
    max = 100 if @author.bot?
    max - @pgsql.exec(
      'SELECT COUNT(*) FROM project WHERE created > NOW() - INTERVAL \'1 DAY\' AND author=$1',
      [@author.id]
    )[0]['count'].to_i
  end

  def recent(badges: [], limit: 10, offset: 0, show_deleted: false)
    terms = []
    terms << 'p.deleted IS NULL' unless show_deleted
    terms << 'badge.text IN (' + badges.map { |b| "'#{b}'" }.join(',') + ')' unless badges.empty?
    q = [
      'SELECT DISTINCT p.*, author.login, author.id AS author_id,',
      'ARRAY(SELECT text FROM badge WHERE project=p.id) as badges',
      'FROM project AS p',
      'LEFT JOIN badge ON p.id=badge.project',
      'JOIN author ON author.id=p.author',
      terms.empty? ? '' : 'WHERE ' + terms.join(' AND '),
      'ORDER BY p.created DESC',
      'LIMIT $1 OFFSET $2'
    ].join(' ')
    @pgsql.exec(q, [limit, offset]).map do |r|
      {
        id: r['id'].to_i,
        coordinates: r['coordinates'],
        author: r['login'],
        author_id: r['author_id'].to_i,
        deleted: r['deleted'],
        badges: r['badges'][1..-2].split(','),
        created: Time.parse(r['created'])
      }
    end
  end
end
