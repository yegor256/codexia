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
require_relative 'xia'
require_relative 'rank'

# Badges.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020-2023 Yegor Bugayenko
# License:: MIT
class Xia::Badge
  attr_reader :id

  def initialize(pgsql, project, id, log: Loog::NULL)
    @pgsql = pgsql
    @project = project
    @id = id
    @log = log
  end

  def text
    @pgsql.exec('SELECT * FROM badge WHERE id=$1', [@id])[0]['text']
  end

  def detach
    Xia::Rank.new(@project.author).enter('badges.detach')
    raise Xia::Urror, 'Can\'t delete the last badge' if @project.badges.to_a.size < 2
    @project.unseen!
    @pgsql.exec('DELETE FROM badge WHERE id=$1', [@id])
  end
end
