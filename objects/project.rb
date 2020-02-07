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
require_relative 'reviews'
require_relative 'badges'

# Project.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020 Yegor Bugayenko
# License:: MIT
class Xia::Project
  attr_reader :id
  attr_reader :author

  def initialize(pgsql, author, id, log: Loog::NULL, tgm: Xia::Tgm::Fake.new)
    @pgsql = pgsql
    @author = author
    @id = id
    @log = log
    @tgm = tgm
  end

  def coordinates
    row[:coordinates]
  end

  def reviews
    Xia::Reviews.new(@pgsql, self, log: @log, tgm: @tgm)
  end

  def badges
    Xia::Badges.new(@pgsql, self, log: @log)
  end

  def delete
    raise Xia::Urror, 'Not enough karma to delete a project' if @author.karma.points < 500
    @pgsql.exec(
      'UPDATE project SET deleted = $2 WHERE id=$1',
      [@id, "Deleted by @#{@author.login} on #{Time.now.utc.iso8601}"]
    )
    @tgm.post(
      "The project ##{@id} `#{row[:coordinates]}` has been deleted",
      "by [@#{@author.login}](https://github.com/#{@author.login})"
    )
  end

  private

  def row
    r = @pgsql.exec(
      'SELECT * FROM project WHERE id=$1',
      [@id]
    )[0]
    raise Xia::Urror, "Project ##{@id} not found in the database" if r.nil?
    {
      id: r['id'].to_i,
      platform: r['platform'],
      coordinates: r['coordinates'],
      author: r['author'].to_i,
      created: Time.parse(r['created'])
    }
  end
end
