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

  def legend
    [
      [
        +1,
        'SELECT * FROM project AS t WHERE author=$1 AND deleted IS NULL',
        'each project you submitted',
        'Project #[id]:[coordinates] submitted'
      ],
      [
        +5,
        [
          'SELECT t.* FROM (',
          '  SELECT *, (SELECT COUNT(*) FROM badge WHERE badge.project=project.id) AS badges',
          '  FROM project',
          '  WHERE author=$1 AND deleted IS NULL',
          ') AS t WHERE badges >= 10'
        ].join(' '),
        'each project with more than one badge',
        'Project #[id]:[coordinates] submitted and got a few badges'
      ],
      [
        +1,
        'SELECT * FROM review AS t WHERE author=$1 AND deleted IS NULL',
        'each review you submitted',
        'Review #[id] submitted'
      ],
      [
        +10,
        'SELECT * FROM review AS t WHERE author=$1 AND deleted IS NULL',
        'each review with 10+ upvotes',
        'Review #[id] has been upvoted 10+ times'
      ],
      [
        0,
        [
          'SELECT * FROM vote AS t',
          'JOIN review ON t.review=review.id',
          'WHERE review.author=$1 AND positive=true'
        ].join(' '),
        'each review up-voted',
        'Review #[id] up-voted'
      ],
      [
        -5,
        [
          'SELECT * FROM vote AS t',
          'JOIN review ON t.review=review.id',
          'WHERE review.author=$1 AND positive=false'
        ].join(' '),
        'each review down-voted',
        'Review #[id] down-voted'
      ],
      [
        -25,
        'SELECT * FROM project AS t WHERE author=$1 AND deleted IS NOT NULL',
        'each project you submitted, which was deleted later',
        'Project #[id]:[coordinates] deleted'
      ],
      [
        -50,
        'SELECT * FROM review AS t WHERE author=$1 AND deleted IS NOT NULL',
        'each review you submitted, which was deleted later',
        'Review #[id] deleted'
      ]
    ]
  end

  def points(safe: false)
    earned = legend.map do |score, q, _text, _summary|
      @pgsql.exec(
        [
          "SELECT COUNT(*) FROM (#{q}) AS q",
          safe ? 'WHERE q.created < NOW() - INTERVAL \'2 DAY\'' : ''
        ].join(' '),
        [@author.id]
      )[0]['count'].to_i * score
    end.inject(&:+)
    paid = @pgsql.exec('SELECT SUM(points) FROM withdrawal WHERE author=$1', [@id])[0]['sum'].to_i
    earned += 1000 if @author.vip?
    @points ||= earned - paid
  end

  def recent(limit: 10)
    legend.map do |score, q, _text, summary|
      @pgsql.exec("#{q} ORDER BY t.created DESC LIMIT $2", [@author.id, limit]).map do |r|
        {
          text: summary.gsub(/\[([a-z]+)\]/) { r[Regexp.last_match[1]] },
          points: score,
          created: Time.parse(r['created'])
        }
      end
    end.flatten.sort_by { |r| r[:created] }.reverse.take(limit)
  end
end
