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

require 'csv'
require 'json'

get '/karma' do
  page = (params[:page] || '0').strip.to_i
  haml :karma, layout: :layout, locals: merged(
    title: '/karma',
    page: page,
    recent: the_author.karma.recent(offset: page * 25, limit: 25),
    withdrawals: the_author.withdrawals.recent(limit: 10)
  )
end

get '/karma.csv' do
  content_type 'text/plain'
  CSV.generate do |csv|
    the_author.karma.recent(limit: 100_000_000).map do |k|
      csv << [k[:created].iso8601, k[:points], k[:text]]
    end
  end
end

get '/karma.json' do
  content_type 'application/json'
  JSON.pretty_generate(
    the_author.karma.recent(limit: 100_000_000).map do |k|
      {
        created: k[:created].iso8601,
        points: k[:points],
        description: k[:text]
      }
    end
  )
end

post '/karma/withdraw' do
  wallet = params[:wallet].strip
  points = params[:points].to_i
  id = the_author.withdrawals.pay(
    wallet, points,
    Zold::WTS.new(settings.config['zold']['token'], log: settings.log),
    settings.config['zold']['keygap']
  )
  flash(iri.cut('/karma'), "We sent #{points} USD to your Zold wallet, payment ID is ##{id}")
end
