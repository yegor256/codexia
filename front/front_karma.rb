# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

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
