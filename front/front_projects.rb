# frozen_string_literal: true

# Copyright (c) 2020 Yegor Bugayenko
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

get '/recent' do
  badges = (params[:badges] || '').strip.split(',')
  page = (params[:page] || '0').strip.to_i
  haml :recent, layout: :layout, locals: merged(
    title: '/recent',
    page: page,
    list: the_author.projects.recent(
      limit: 25,
      offset: page * 25,
      badges: badges,
      show_deleted: the_author.karma.points > 100
    )
  )
end

get '/recent.json' do
  content_type 'application/json'
  JSON.pretty_generate(
    the_author.projects.recent(
      limit: 25,
      offset: (params[:page] || '0').strip.to_i * 25,
      show_deleted: true
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
  project = the_author.projects.submit(platform, coordinates)
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
