# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../objects/rank'

get '/recent' do
  badges = (params[:badges] || '').strip.split(',')
  page = (params[:page] || '0').strip.to_i
  haml :recent, layout: :layout, locals: merged(
    title: '/recent',
    page: page,
    list: the_projects.recent(
      limit: 25,
      offset: page * 25,
      badges: badges,
      show_deleted: Xia::Rank.new(the_author).ok?('projects.show-deleted') && params[:show_deleted]
    )
  )
end

get '/inbox' do
  page = (params[:page] || '0').strip.to_i
  haml :recent, layout: :layout, locals: merged(
    title: '/inbox',
    page: page,
    list: the_projects.inbox(limit: 25, offset: page * 25)
  )
end

get '/recent.json' do
  content_type 'application/json'
  JSON.pretty_generate(
    the_projects.recent(
      limit: 25,
      offset: (params[:page] || '0').strip.to_i * 25,
      show_deleted: Xia::Rank.new(the_author).ok?('projects.show-deleted') && params[:show_deleted]
    )
  )
end

get '/submit' do
  haml :submit, layout: :layout, locals: merged(
    title: '/submit'
  )
end

post '/submit' do
  platform = params[:platform]
  raise Xia::Urror, '"platform" is a mandatory parameter' if platform.nil?
  coordinates = params[:coordinates]
  raise Xia::Urror, '"coordinates" is a mandatory parameter' if coordinates.nil?
  project = the_projects.submit(platform.strip, coordinates.strip)
  if params[:noredirect]
    return JSON.pretty_generate(
      id: project.id,
      coordinates: project.coordinates,
      platform: project.platform,
      uri: iri.cut('/p').append(project.id)
    )
  end
  flash(iri.cut('/p').append(project.id), "A new project #{project.id} has been submitted!")
end
