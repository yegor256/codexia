# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

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
  token = (request.env['HTTP_X_CODEXIA_TOKEN'] || '').strip
  unless token.empty?
    begin
      login = settings.codec.decrypt(token)
      @locals[:author] = { login: login }
    rescue OpenSSL::Cipher::CipherError
      raise Xia::Urror, "Invalid token #{token.inspect} for #{login.inspect}, sorry"
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
  flash('/', "You have been logged in as #{u['login']}")
end

get '/logout' do
  cookies.delete(:glogin)
  flash('/', 'You have been logged out')
end
