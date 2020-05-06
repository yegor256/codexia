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
require_relative 'bots'
require_relative 'veil'
require_relative 'sieve'

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
    Xia::Sieve.new(
      Xia::Project.new(@pgsql, @author, id, log: @log, telepost: @telepost),
      :id, :coordinates, :platform, :created, :deleted, :submitter, :badges, :meta
    )
  end

  def submit(platform, coordinates)
    Xia::Rank.new(@author).enter('projects.submit')
    raise Xia::Urror, "You @#{@author.login} are submitting too fast" if quota.negative?
    unless %r{^[A-Za-z0-9\-\.]+/[A-Za-z0-9\-_\.]+$}.match?(coordinates)
      raise Xia::Urror, "Coordinates #{coordinates.inspect} are wrong"
    end
    %w[
      google facebook facebookresearch facebookincubator
      ibm oracle intel alibaba aws pivotal mozilla uber netflix
    ].each do |org|
      if %r{^#{org}/}i.match?(coordinates)
        raise Xia::Urror, "This project most likely is already sponsored by a large enterprise '#{org}'"
      end
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
    unless Xia::Bots.new.is?(@author)
      @telepost.spam(
        "😍 New #{platform} project [#{coordinates}](https://www.codexia.org/p/#{id}) has been submitted",
        "by [@#{@author.login}](https://github.com/#{@author.login})"
      )
    end
    project
  end

  def quota
    return 1 if @author.vip?
    max = 5
    max = 100 if Xia::Bots.new.is?(@author)
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
      'SELECT DISTINCT p.*, author.login AS author_login, author.id AS author_id,',
      'ARRAY(SELECT CONCAT(id,\':\',text) FROM badge WHERE project=p.id) as badges',
      'FROM project AS p',
      'LEFT JOIN badge ON p.id=badge.project',
      'JOIN author ON author.id=p.author',
      terms.empty? ? '' : 'WHERE ' + terms.join(' AND '),
      'ORDER BY p.created DESC',
      'LIMIT $1 OFFSET $2'
    ].join(' ')
    @pgsql.exec(q, [limit, offset]).map do |r|
      p = get(r['id'].to_i)
      Xia::Sieve.new(
        Xia::Veil.new(
          p,
          id: p.id,
          coordinates: r['coordinates'],
          platform: r['platform'],
          deleted: r['deleted'],
          created: Time.parse(r['created']),
          submitter: Xia::Sieve.new(
            Xia::Veil.new(
              Xia::Author.new(@pgsql, r['author_id'].to_i, log: @log, telepost: @telepost),
              id: r['author_id'].to_i,
              login: r['author_login']
            ),
            :id, :login
          ),
          badges: Xia::Sieve.new(
            Xia::Veil.new(
              Xia::Badges.new(@pgsql, p, log: @log),
              to_a: r['badges'][1..-2].split(',').map do |t|
                id, text = t.split(':', 2)
                Xia::Sieve.new(
                  Xia::Veil.new(
                    Xia::Badge.new(@pgsql, p, id, log: @log),
                    id: id,
                    text: text
                  ),
                  :id, :text
                )
              end
            ),
            :to_a
          )
        ),
        :id, :coordinates, :platform, :created, :deleted, :submitter, :badges
      )
    end
  end
end
