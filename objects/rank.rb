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
require_relative 'bots'

# The rank of an author.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020 Yegor Bugayenko
# License:: MIT
class Xia::Rank
  def initialize(author, log: Loog::NULL)
    @author = author
    @log = log
  end

  def legend
    [
      {
        task: 'withdraw',
        min: 100,
        text: 'convert karma to cash'
      },
      {
        task: 'projects.submit',
        min: 0,
        text: 'submit a new project'
      },
      {
        task: 'projects.submit.quota.5',
        min: 100,
        text: 'submit more than 5 projects per day'
      },
      {
        task: 'projects.submit.quota.50',
        min: 500,
        text: 'submit more than 50 projects per day'
      },
      {
        task: 'projects.show-deleted',
        min: 100,
        text: 'see deleted projects'
      },
      {
        task: 'projects.delete',
        min: 500,
        text: 'delete an existing project',
        bot_forbid: true
      },
      {
        task: 'projects.delete-own',
        min: 0,
        text: 'delete your own project'
      },
      {
        task: 'reviews.post',
        min: 0,
        text: 'post a review'
      },
      {
        task: 'reviews.post.quota.50',
        min: 100,
        text: 'post most than 50 reviews per day'
      },
      {
        task: 'reviews.post.quota.200',
        min: 500,
        text: 'post most than 200 reviews per day'
      },
      {
        task: 'reviews.show-deleted',
        min: 100,
        text: 'see deleted reviews'
      },
      {
        task: 'reviews.delete',
        min: 500,
        text: 'delete an existing review',
        bot_forbid: true
      },
      {
        task: 'reviews.delete-own',
        min: 0,
        text: 'delete its own existing review',
        bot_forbid: false
      },
      {
        task: 'reviews.upvote',
        min: 100,
        text: 'upvote a review',
        bot_forbid: true
      },
      {
        task: 'reviews.downvote',
        min: 200,
        text: 'downvote a review',
        bot_forbid: true
      },
      {
        task: 'reviews.vote.quota.50',
        min: 100,
        text: 'vote more than 50 times per day'
      },
      {
        task: 'reviews.vote.quota.200',
        min: 500,
        text: 'vote more than 20 times per day'
      },
      {
        task: 'badges.promote-to-L1',
        min: 500,
        text: 'promote a project to L1',
        bot_forbid: true
      },
      {
        task: 'badges.promote-to-L2',
        min: 2000,
        text: 'promote a project to L2',
        bot_forbid: true
      },
      {
        task: 'badges.promote-to-L3',
        min: 5000,
        text: 'promote a project to L3',
        bot_forbid: true
      },
      {
        task: 'badges.degrade-from-L3',
        min: 3000,
        text: 'degrade an L3 project',
        bot_forbid: true
      },
      {
        task: 'badges.degrade-from-L2',
        min: 1000,
        text: 'degrade an L2 project',
        bot_forbid: true
      },
      {
        task: 'badges.degrade-from-L1',
        min: 300,
        text: 'degrade an L1 project',
        bot_forbid: true
      },
      {
        task: 'badges.attach',
        min: 1,
        text: 'attach a new badge'
      },
      {
        task: 'badges.detach',
        min: 2000,
        text: 'detach an existing badge'
      }
    ]
  end

  def ok?(task, safe: false)
    return true if @author.vip?
    info = legend.find { |i| i[:task] == task }
    raise "Unknown task #{task.inspect}" if info.nil?
    karma = @author.karma.points(safe: safe)
    return false if info[:min] && karma < info[:min]
    true
  end

  def enter(task, safe: false)
    return if @author.vip?
    info = legend.find { |i| i[:task] == task }
    raise "Unknown task #{task.inspect}" if info.nil?
    if info[:bot_forbid] && Xia::Bots.new.is?(@author)
      raise Xia::Urror, "The bot @#{@author.login} can't #{info[:text]}"
    end
    karma = @author.karma.points(safe: safe)
    txt = format('%+d', karma)
    if info[:min] && karma < info[:min]
      raise Xia::Urror, "Can't #{info[:text]} with a negative karma #{txt}" if karma.negative?
      raise Xia::Urror, "Karma #{txt} is not enough to #{info[:text]} (must be #{info[:min]}+)"
    end
    karma
  end

  def quota(entity, task)
    return if @author.vip?
    footprint = @author.footprint(entity)
    prefix = "#{entity}s.#{task}.quota."
    t = legend.select { |g| g[:task].start_with?(prefix) }
      .map { |g| { task: g[:task], diff: footprint - g[:task][prefix.length..-1].to_i } }
      .reject { |g| g[:diff].negative? }
      .min_by { |g| g[:diff] }
    Xia::Rank.new(@author, log: @log).enter(t[:task]) unless t.nil?
  end
end
