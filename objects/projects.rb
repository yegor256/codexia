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
require_relative 'project'

# Projects.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020 Yegor Bugayenko
# License:: MIT
class Xia::Projects
  def initialize(pgsql, author)
    @pgsql = pgsql
    @author = author
  end

  def get(id)
    Xia::Project.new(@pgsql, @author, id)
  end

  def submit(platform, coordinates)
    raise Xia::Urror, 'Not enough karma to submit a project' unless @author.karma.positive?
    id = @pgsql.exec(
      'INSERT INTO project (platform, coordinates, author) VALUES ($1, $2, $3) RETURNING id',
      [platform, coordinates, @author.id]
    )[0]['id'].to_i
    get(id)
  end

  def recent(limit: 10)
    q = [
      'SELECT project.*, author.login',
      'FROM project',
      'JOIN author ON author.id=project.author',
      'WHERE project.deleted IS NULL',
      'ORDER BY project.created DESC',
      'LIMIT $1'
    ].join(' ')
    @pgsql.exec(q, [limit]).map do |r|
      {
        id: r['id'].to_i,
        coordinates: r['coordinates'],
        author: r['login'],
        created: Time.parse(r['created'])
      }
    end
  end
end
