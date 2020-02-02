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

before '/*' do
  @locals = {
    http_start: Time.now,
    ver: Xia::VERSION,
    login_link: settings.glogin.login_uri,
    request_ip: request.ip
  }
  cookies[:glogin] = params[:glogin] if params[:glogin]
  if cookies[:glogin]
    begin
      @locals[:author] = GLogin::Cookie::Closed.new(
        cookies[:glogin],
        settings.config['github']['encryption_secret'],
        context
      ).to_user
    rescue GLogin::Codec::DecodingError
      cookies.delete(:glogin)
    end
  end
end

get '/github-callback' do
  code = params[:code]
  error(400) if code.nil?
  u = settings.glogin.user(code)
  cookies[:glogin] = GLogin::Cookie::Open.new(
    u,
    settings.config['github']['encryption_secret'],
    context
  ).to_s
  the_author.avatar = u[:avatar]
  flash('/', "You have been logged in as #{u[:glogin]}")
end

get '/logout' do
  cookies.delete(:glogin)
  flash('/', 'You have been logged out')
end
