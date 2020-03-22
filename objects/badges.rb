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
require_relative 'badge'

# Badges.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020 Yegor Bugayenko
# License:: MIT
class Xia::Badges
  # When such a badge already exists and we can't attach a new one.
  class DuplicateError < Xia::Urror; end

  def initialize(pgsql, project, log: Loog::NULL)
    @pgsql = pgsql
    @project = project
    @log = log
  end

  # A badge is already attached?
  def exists?(text)
    !@pgsql.exec(
      'SELECT COUNT(*) FROM badge WHERE project=$1 AND text=$2',
      [@project.id, text]
    )[0]['count'].to_i.zero?
  end

  # Get current level of the project, either 0 (newbie) or 1 (L1), 2 (L2), etc.
  def level
    txt = all.map { |b| b[:text] }.find { |b| /^(L[0-9]|newbie)$/.match?(b) }
    return 0 if txt.nil?
    return 0 if txt == 'newbie'
    txt[1].to_i
  end

  def get(id)
    Xia::Badge.new(@pgsql, @project, id, log: @log)
  end

  def all
    @pgsql.exec('SELECT * FROM badge WHERE project=$1', [@project.id]).map do |r|
      {
        id: r['id'].to_i,
        text: r['text']
      }
    end
  end

  def attach(text)
    Xia::Rank.new(@project.author).enter('badges.attach')
    raise DuplicateError, "The badge #{text.inspect} is already attached" if exists?(text)
    raise Xia::Urror, "The badge #{text.inspect} looks wrong" unless /^([a-z0-9]{3,12}|L[0-9])$/.match?(text)
    if /^(newbie|L[0-9])$/.match?(text)
      after = text == 'newbie' ? 0 : text[1].to_i
      before = level
      Xia::Rank.new(@project.author).enter("badges.promote-to-#{text}") if after > before
      Xia::Rank.new(@project.author).enter("badges.degrade-from-L#{before}") if after < before
    elsif all.length >= 5
      raise Xia::Urror, 'Too many badges already'
    end
    id = @pgsql.exec(
      'INSERT INTO badge (project, text) VALUES ($1, $2) RETURNING id',
      [@project.id, text]
    )[0]['id'].to_i
    get(id)
  end
end
