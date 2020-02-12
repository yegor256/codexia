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
require 'telepost'
require_relative 'xia'

# Meta.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020 Yegor Bugayenko
# License:: MIT
class Xia::Meta
  def initialize(pgsql, project, log: Loog::NULL, telepost: Telepost::Fake.new)
    @pgsql = pgsql
    @project = project
    @log = log
    @telepost = telepost
  end

  def set(key, value)
    raise Xia::Urror, 'The value can\'t be empty' if value.empty?
    raise Xia::Urror, 'The key can\'t be empty' if key.empty?
    raise Xia::Urror, 'The key may include letters, numbers, and dashes only' unless /^[a-zA-Z0-9-]+$/.match?(key)
    raise Xia::Urror, 'The value is too large (over 256)' if value.length > 256
    id = @pgsql.exec(
      [
        'INSERT INTO meta (project, author, key, value) VALUES ($1, $2, $3, $4)',
        'ON CONFLICT (project, author, key) DO UPDATE SET value = $4 RETURNING id'
      ].join(' '),
      [@project.id, @project.author.id, key, value]
    )[0]['id'].to_i
    @telepost.spam(
      "New meta `#{key}` set for the project",
      "[`#{@project.coordinates}`](https://www.codexia.org/p/#{@project.id})",
      "by [@#{@project.author.login}](https://github.com/#{@project.author.login})"
    )
    id
  end

  def value(key)
    a, k = key.split(':', 2)
    row = @pgsql.exec(
      'SELECT value FROM meta JOIN author ON author.id=meta.author WHERE project=$1 AND login=$2 AND key=$3',
      [@project.id, a, k]
    )[0]
    raise Xia::Urror, "The key #{key.inspect} is not found" if row.nil?
    row['value']
  end

  def all
    q = [
      'SELECT m.*, author.login AS login',
      'FROM meta AS m',
      'JOIN author ON author.id=m.author',
      'WHERE project=$1'
    ].join(' ')
    @pgsql.exec(q, [@project.id]).map do |r|
      {
        id: r['id'].to_i,
        author: r['login'],
        key: "#{r['login']}:#{r['key']}",
        value: r['value'],
        updated: Time.parse(r['updated'])
      }
    end
  end
end
