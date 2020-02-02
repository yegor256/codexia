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
require_relative 'urror'
require_relative 'projects'

# One author.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020 Yegor Bugayenko
# License:: MIT
class Xia::Author
  attr_reader :id

  def initialize(pgsql, id)
    @pgsql = pgsql
    @id = id
  end

  def karma
    return 1_000_000 if login == 'yegor256' || ENV['RACK_ENV'] == 'test'
    projects = @pgsql.exec('SELECT COUNT(*) FROM project WHERE author=$1', [@id])[0]['count'].to_i
    reviews = @pgsql.exec('SELECT COUNT(*) FROM review WHERE author=$1', [@id])[0]['count'].to_i
    projects * 5 + reviews + 10
  end

  def projects
    Xia::Projects.new(@pgsql, self)
  end

  def login
    row['login']
  end

  def avatar
    row['avatar']
  end

  def avatar=(url)
    @pgsql.exec(
      'UPDATE author SET avatar=$2 WHERE id=$1',
      [@id, url]
    )
  end

  private

  def row
    row = @pgsql.exec(
      'SELECT avatar FROM author WHERE id=$1',
      [@id]
    )[0]
    raise Xia::Urror, "Author @#{@login} not found in the database" if row.nil?
    row
  end
end
