# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

get '/sql' do
  raise Xia::Urror, 'You are not allowed to see this' unless the_author.vip?
  query = params[:query] || 'SELECT * FROM author LIMIT 16'
  haml :sql, layout: :layout, locals: merged(
    title: '/sql',
    query: query,
    result: settings.pgsql.exec(query)
  )
end
