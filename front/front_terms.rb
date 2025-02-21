# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../objects/rank'

get '/terms' do
  haml :terms, layout: :layout, locals: merged(
    title: '/terms',
    karma_legend: the_author.karma.legend,
    rank_legend: Xia::Rank.new(the_author).legend
  )
end

get '/focus' do
  haml :focus, layout: :layout, locals: merged(
    title: '/focus'
  )
end
