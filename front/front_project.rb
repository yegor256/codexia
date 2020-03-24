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

require 'digest'

get '/p/{id}.json' do
  project = the_author.projects.get(params[:id].to_i)
  content_type 'application/json'
  JSON.pretty_generate(
    id: project.id,
    coordinates: project.coordinates,
    platform: project.platform,
    author: project.submitter,
    created: project.created,
    deleted: project.deleted
  )
end

get '/p/{id}/reviews.json' do
  project = the_author.projects.get(params[:id].to_i)
  content_type 'application/json'
  page = (params[:page] || '0').strip.to_i
  JSON.pretty_generate(
    project.reviews.recent(
      limit: 25,
      offset: page * 25
    )
  )
end

get '/p/{id}' do
  project = the_author.projects.get(params[:id].to_i)
  page = (params[:page] || '0').strip.to_i
  haml :project, layout: :layout, locals: merged(
    title: project.coordinates,
    project: project,
    page: page,
    reviews: project.reviews.recent(
      limit: 25,
      offset: page * 25,
      show_deleted: the_author.karma.points > 100
    )
  )
end

get '/p/{id}/delete' do
  project = the_author.projects.get(params[:id].to_i)
  project.delete
  flash(iri.cut('/recent'), "The project ##{project.id} has been deleted")
end

get '/p/{id}/r/{rid}/delete' do
  project = the_author.projects.get(params[:id].to_i)
  review = project.reviews.get(params[:rid].to_i)
  review.delete
  flash(iri.cut('/p').append(project.id), "The review ##{review.id} in the project ##{project.id} removed")
end

get '/p/{id}/r/{rid}/up' do
  project = the_author.projects.get(params[:id].to_i)
  review = project.reviews.get(params[:rid].to_i)
  review.vote(true)
  flash(iri.cut('/p').append(project.id), "The review ##{review.id} in the project ##{project.id} upvoted")
end

get '/p/{id}/r/{rid}/down' do
  project = the_author.projects.get(params[:id].to_i)
  review = project.reviews.get(params[:rid].to_i)
  review.vote(false)
  flash(iri.cut('/p').append(project.id), "The review ##{review.id} in the project ##{project.id} downvoted")
end

get '/duplicate/{id}' do
  flash(iri.cut('/p').append(project.id))
end

post '/p/{id}/post' do
  project = the_author.projects.get(params[:id].to_i)
  text = params[:text].strip
  hash = params[:hash] || Digest::MD5.hexdigest(text)
  review = project.reviews.post(text, hash.strip)
  flash(iri.cut('/p').append(project.id), "A new review ##{review.id} has been posted to the project ##{project.id}")
rescue Xia::Reviews::DuplicateError => e
  flash(iri.cut('/duplicate'), "Duplicate review: #{e.message}")
end

post '/p/{id}/attach' do
  project = the_author.projects.get(params[:id].to_i)
  badge = project.badges.attach(params[:text].strip)
  flash(iri.cut('/p').append(project.id), "A new badge ##{badge.id} has been attached to the project ##{project.id}")
rescue Xia::Badges::DuplicateError => e
  flash(iri.cut('/duplicate'), "Duplicate badge: #{e.message}")
end

get '/p/{id}/detach/{badge}' do
  project = the_author.projects.get(params[:id].to_i)
  badge = project.badges.get(params[:badge].to_i)
  badge.detach
  flash(iri.cut('/p').append(project.id), "The badge ##{badge.id} has been detached from the project ##{project.id}")
end

get '/p/{id}/badges.json' do
  project = the_author.projects.get(params[:id].to_i)
  JSON.pretty_generate(project.badges.all)
end

get '/p/{id}/meta' do
  project = the_author.projects.get(params[:id].to_i)
  content_type 'text/plain'
  project.meta.value(params[:key].strip)
end

post '/p/{id}/meta' do
  project = the_author.projects.get(params[:id].to_i)
  id = project.meta.set(params[:key].strip, params[:value].strip)
  flash(iri.cut('/p').append(project.id), "A new meta ##{id} set for the project ##{project.id}")
end
