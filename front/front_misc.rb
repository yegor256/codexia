# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

get '/js/*.js' do
  file = File.join('js', params[:splat].first) + '.js'
  error(404, "File not found: #{file}") unless File.exist?(file)
  content_type 'application/javascript'
  IO.read(file)
end

get '/robots.txt' do
  content_type 'text/plain'
  "User-agent: *\nDisallow: /"
end

get '/version' do
  content_type 'text/plain'
  Xia::VERSION
end

not_found do
  status 404
  content_type 'text/html', charset: 'utf-8'
  haml :not_found, layout: :layout, locals: merged(
    title: request.url
  )
end

error do
  status 503
  e = env['sinatra.error']
  if e.is_a?(Xia::Urror)
    flash(@locals[:author] ? '/recent' : '/', e.message, color: 'darkred', code: 303)
  elsif e.is_a?(Xia::NotFound)
    flash(@locals[:author] ? '/recent' : '/', e.message, color: 'darkred', code: 404)
  else
    Raven.capture_exception(e)
    haml(
      :error,
      layout: nil,
      locals: merged(
        title: 'error',
        error: "#{e.message}\n\t#{e.backtrace.join("\n\t")}"
      )
    )
  end
end

def context
  "#{request.ip} #{Xia::VERSION} #{Time.now.strftime('%Y/%m')}"
end

def merged(hash = {})
  out = @locals.merge(hash)
  out[:local_assigns] = out
  if cookies[:flash_msg]
    out[:flash_msg] = cookies[:flash_msg]
    cookies.delete(:flash_msg)
  end
  out[:flash_color] = cookies[:flash_color] || 'darkgreen'
  cookies.delete(:flash_color)
  out
end

def flash(uri, msg = '', color: 'darkgreen', code: 302)
  cookies[:flash_msg] = msg
  cookies[:flash_color] = color
  redirect uri, code
end
