# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

get '/bots' do
  raise Xia::Urror, 'You are not allowed to see this' unless the_author.vip?
  haml :bots, layout: :layout, locals: merged(
    title: '/bots',
    bots: Xia::Bots.new(settings.pgsql).authors
  )
end
