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

get '/p/{id}' do
  project = the_author.projects.get(params[:id].to_i)
  haml :project, layout: :layout, locals: merged(
    title: project.coordinates,
    project: project,
    reviews: project.reviews.recent(limit: 25, show_deleted: the_author.karma.points > 100)
  )
end

get '/p/{id}.json' do
  content_type 'application/json'
  JSON.pretty_generate(project.reviews.recent(limit: 25))
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

post '/p/{id}/post' do
  project = the_author.projects.get(params[:id].to_i)
  review = project.reviews.post(params[:text].strip)
  flash(iri.cut('/p').append(project.id), "A new review ##{review.id} has been posted to the project ##{project.id}")
end

post '/p/{id}/attach' do
  project = the_author.projects.get(params[:id].to_i)
  badge = project.badges.attach(params[:text].strip)
  flash(iri.cut('/p').append(project.id), "A new badge ##{badge.id} has been attached to the project ##{project.id}")
end
