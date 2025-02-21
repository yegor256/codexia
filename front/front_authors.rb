# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

get '/authors' do
  haml :authors, layout: :layout, locals: merged(
    title: '/authors',
    list: the_authors.best
  )
end
