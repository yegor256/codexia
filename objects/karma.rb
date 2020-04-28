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
require_relative 'urror'
require_relative 'withdrawals'
require_relative 'bots'

# Karma.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020 Yegor Bugayenko
# License:: MIT
class Xia::Karma
  attr_reader :author

  def initialize(pgsql, author, log: Loog::NULL)
    @pgsql = pgsql
    @author = author
    @log = log
  end

  def to_json(options)
    {
      points: points,
      safe: points(safe: true)
    }.to_json(options)
  end

  def legend
    [
      {
        points: {
          '2000-01-01': +1
        },
        query: 'SELECT * FROM project AS t WHERE author=$1 AND deleted IS NULL',
        terms: 'each project you submitted',
        history: 'The project #[id]:[coordinates] you submitted',
        bot: {
          '2020-04-22': +0.8,
          '2000-01-01': +1
        }
      },
      {
        points: {
          '2000-01-01': +5
        },
        query: [
          'SELECT DISTINCT t.id, t.coordinates, t.created FROM project AS t',
          'JOIN badge ON badge.project=t.id AND badge.text LIKE \'L%\'',
          'WHERE t.author=$1 AND t.deleted IS NULL'
        ].join(' '),
        terms: 'each promoted project',
        history: 'The project #[id]:[coordinates] you submitted got a promotion',
        bot: {
          '2020-04-22': +2,
          '2000-01-01': +5
        }
      },
      {
        points: {
          '2000-01-01': +1
        },
        query: 'SELECT * FROM review AS t WHERE author=$1 AND deleted IS NULL',
        terms: 'each review you submitted',
        history: 'The review #[id] you submitted',
        bot: {
          '2020-04-22': +0.1,
          '2000-01-01': +1
        }
      },
      {
        points: {
          '2000-01-01': 0
        },
        query: [
          'SELECT DISTINCT t.id, t.created FROM review AS t',
          'JOIN project ON t.project=project.id',
          'JOIN badge ON project.id=badge.project AND badge.text LIKE \'L%\'',
          'WHERE t.author=$1 AND t.deleted IS NULL'
        ].join(' '),
        terms: 'each review you submitted for L1+ project',
        history: 'The review #[id] you submitted for L1+ project',
        bot: {
          '2020-04-22': +0.8,
          '2000-01-01': 0
        }
      },
      {
        points: {
          '2000-01-01': +10
        },
        query: [
          'SELECT t.* FROM (',
          '  SELECT *, (SELECT COUNT(*) FROM vote WHERE review.id=vote.review AND positive=true) AS votes',
          '  FROM review',
          '  WHERE author=$1 AND deleted IS NULL',
          ') AS t WHERE votes >= 10'
        ].join(' '),
        terms: 'each review of yours, which collected 10+ upvotes',
        history: 'Your review #[id] was upvoted 10+ times',
        bot: {
          '2020-04-22': 0,
          '2000-01-01': +10
        }
      },
      {
        points: {
          '2020-04-22': +1
        },
        query: [
          'SELECT t.* FROM vote AS t',
          'JOIN review ON t.review=review.id',
          'WHERE review.author=$1 AND positive=true'
        ].join(' '),
        terms: 'each review of yours, which was up-voted',
        history: 'You review #[id] was up-voted',
        bot: {
          '2000-01-01': 0
        }
      },
      {
        points: {
          '2000-01-01': -5
        },
        query: [
          'SELECT t.* FROM vote AS t',
          'JOIN review ON t.review=review.id',
          'WHERE review.author=$1 AND positive=false'
        ].join(' '),
        terms: 'each review of yours, which was down-voted',
        history: 'Your review #[id] was down-voted',
        bot: {
          '2020-04-22': -0.5,
          '2000-01-01': -5
        }
      },
      {
        points: {
          '2020-04-22': -40,
          '2000-01-01': -25
        },
        query: 'SELECT t.* FROM project AS t WHERE author=$1 AND deleted IS NOT NULL',
        terms: 'each project you submitted, which was deleted later',
        history: 'The project #[id]:[coordinates] you submitted was deleted',
        bot: {
          '2020-04-22': -10,
          '2000-01-01': -25
        }
      },
      {
        points: {
          '2020-04-22': -25,
          '2000-01-01': -50
        },
        query: 'SELECT * FROM review AS t WHERE author=$1 AND deleted IS NOT NULL',
        terms: 'each review you submitted, which was deleted later',
        history: 'The review #[id] you submitted was deleted',
        bot: {
          '2020-04-22': -10,
          '2000-01-01': -50
        }
      }
    ]
  end

  # Forcefully add this points to the karma (the user won't be able to withdraw them).
  def add(points, wallet, zents)
    @pgsql.exec(
      'INSERT INTO withdrawal (author, wallet, points, zents) VALUES ($1, $2, $3, $4) RETURNING id',
      [@author.id, wallet, points, zents]
    )[0]['id'].to_i
  end

  def points(safe: false)
    bot = Xia::Bots.new.is?(@author)
    earned = legend.map do |g|
      s = { (Time.now + 24 * 60 * 60).iso8601.to_s[0..9] => 0 }.merge(bot ? g[:bot] : g[:points]).to_a
      (1..s.count - 1).map { |i| [s[i - 1][0], s[i][0], s[i][1]] }.map do |t1, t2, _|
        @pgsql.exec(
          [
            "SELECT COUNT(*) FROM (#{g[:query]}) AS q",
            'WHERE q.created < $2 AND q.created > $3',
            safe ? 'AND q.created < NOW() - INTERVAL \'2 DAY\'' : ''
          ].join(' '),
          [@author.id, t1, t2]
        )[0]['count'].to_i * pts(g, Time.parse(t2.to_s))
      end.inject(&:+)
    end.inject(&:+)
    paid = @pgsql.exec('SELECT SUM(points) FROM withdrawal WHERE author=$1', [@author.id])[0]['sum'].to_i
    earned -= (paid + 100) if safe
    earned += paid unless safe
    earned
  end

  def recent(offset: 0, limit: 10)
    legend.map do |g|
      q = "#{g[:query]} ORDER BY t.created DESC LIMIT $2 OFFSET $3"
      @pgsql.exec(q, [@author.id, limit, offset]).map do |r|
        created = Time.parse(r['created'])
        {
          text: g[:history].gsub(/\[([a-z]+)\]/) { r[Regexp.last_match[1]] },
          points: pts(g, created),
          created: created
        }
      end
    end.flatten.reject { |r| r[:points].zero? }.sort_by { |r| r[:created] }.reverse.take(limit)
  end

  private

  def pts(g, created)
    bot = Xia::Bots.new.is?(@author)
    schedule = bot ? g[:bot] : g[:points]
    s = schedule.select { |t, _| Time.parse(t.to_s) <= created }.sort_by { |t, _| t }.reverse.first
    raise "Oops in #{g[:terms]}: #{schedule}, #{created}" if s.nil?
    s[1]
  end
end
