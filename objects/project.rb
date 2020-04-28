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
require_relative 'meta'
require_relative 'rank'
require_relative 'bots'
require_relative 'veil'

# Project.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020 Yegor Bugayenko
# License:: MIT
class Xia::Project
  attr_reader :id
  attr_reader :author

  def initialize(pgsql, author, id, log: Loog::NULL, telepost: Telepost::Fake.new)
    @pgsql = pgsql
    @author = author
    @id = id
    @log = log
    @telepost = telepost
  end

  def coordinates
    column(:coordinates)
  end

  def platform
    column(:platform)
  end

  def deleted
    column(:deleted)
  end

  def created
    Time.parse(column(:created))
  end

  def submitter
    Xia::Sieve.new(
      Xia::Author.new(@pgsql, column(:author).to_i, log: @log, telepost: @telepost),
      :id, :login, :karma
    )
  end

  def reviews
    Xia::Sieve.new(
      Xia::Reviews.new(@pgsql, self, log: @log, telepost: @telepost),
      :to_a
    )
  end

  def badges
    Xia::Sieve.new(
      Xia::Badges.new(@pgsql, self, log: @log),
      :to_a
    )
  end

  def meta
    raise Xia::Urror, 'You are not allowed to use meta' unless Xia::Bots.new.is?(@author)
    Xia::Sieve.new(
      Xia::Meta.new(@pgsql, self, log: @log, telepost: @telepost),
      :to_a
    )
  end

  def delete
    Xia::Rank.new(@author).enter('projects.delete')
    @pgsql.exec(
      'UPDATE project SET deleted = $2 WHERE id=$1',
      [@id, "Deleted by @#{@author.login} on #{Time.now.utc.iso8601}"]
    )
    @telepost.spam(
      "The project no.#{@id} [#{coordinates}](https://github.com/#{coordinates}) has been deleted",
      "by [@#{@author.login}](https://github.com/#{@author.login})",
      "(it was earlier submitted by [@#{submitter.login}](https://github.com/#{submitter.login}))"
    )
  end

  private

  def column(name)
    r = @pgsql.exec("SELECT #{name} FROM project WHERE id=$1", [@id])[0]
    raise Xia::Urror, "Project ##{@id} not found in the database" if r.nil?
    r[name.to_s]
  end
end
