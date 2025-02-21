# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

get '/a/{a}' do
  a = the_authors.named(params[:a].downcase)
  haml :author, layout: :layout, locals: merged(
    title: a.login,
    a: a
  )
end
