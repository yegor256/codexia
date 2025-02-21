# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

get '/payables' do
  raise Xia::Urror, 'You are not allowed to see this' unless the_author.vip?
  a = the_authors.named(params[:a].downcase)
  page = (params[:page] || '0').strip.to_i
  haml :payables, layout: :layout, locals: merged(
    title: '/payables',
    a: a,
    recent: a.karma.recent(limit: 25, offset: page * 25),
    page: page
  )
end
