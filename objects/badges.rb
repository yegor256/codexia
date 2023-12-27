# frozen_string_literal: true

# Copyright (c) 2020-2023 Yegor Bugayenko
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
require 'veil'
require_relative 'xia'
require_relative 'badge'
require_relative 'bots'

# Badges.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020-2023 Yegor Bugayenko
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
    txt = to_a.map(&:text).find { |b| /^(L[123]|newbie)$/.match?(b) }
    return 0 if txt.nil?
    return 0 if txt == 'newbie'
    txt[1].to_i
  end

  def get(id)
    Xia::Badge.new(@pgsql, @project, id, log: @log)
  end

  def to_a
    @pgsql.exec('SELECT * FROM badge WHERE project=$1', [@project.id]).map do |r|
      Xia::Sieve.new(
        Veil.new(
          get(r['id'].to_i),
          text: r['text']
        ),
        :id, :text
      )
    end
  end

  def attach(text)
    Xia::Rank.new(@project.author).enter('badges.attach')
    raise DuplicateError, "The badge #{text.inspect} is already attached" if exists?(text)
    raise Xia::Urror, "The badge #{text.inspect} looks wrong" unless /^([a-z0-9]{3,12}|L[123])$/.match?(text)
    delete = false
    if /^(newbie|L[123])$/.match?(text)
      after = text == 'newbie' ? 0 : text[1].to_i
      if Xia::Bots.new.is?(@project.author) && after.positive?
        raise Xia::Urror, "The bot @#{@project.author.login} can't promote/degrade a project to L#{after}"
      end
      before = level
      reviews = Xia::Reviews.new(@pgsql, @project, log: @log)
      if after > before
        Xia::Rank.new(@project.author).enter("badges.promote-to-#{text}")
        reviews.post("The project has been promoted from L#{before} to L#{after}")
      end
      if after < before
        Xia::Rank.new(@project.author).enter("badges.degrade-from-L#{before}")
        reviews.post("The project has been degraded from L#{before} to L#{after}")
      end
      delete = true
    elsif to_a.length >= 5
      raise Xia::Urror, 'Too many badges already'
    end
    id = @pgsql.transaction do |t|
      if delete
        t.exec(
          'DELETE FROM badge WHERE project=$1 AND text SIMILAR TO \'(newbie|L[123])\'',
          [@project.id]
        )
      end
      t.exec(
        [
          'INSERT INTO badge (project, author, text) VALUES ($1, $2, $3)',
          'ON CONFLICT (project, text) DO UPDATE SET text = $2 RETURNING id'
        ].join(' '),
        [@project.id, @project.author.id, text]
      )[0]['id'].to_i
    end
    @project.unseen!
    unless /^(newbie|L[123])$/.match?(text)
      @project.reviews.post("A new badge #{text.inspect} was attached to the project")
    end
    get(id)
  end
end
