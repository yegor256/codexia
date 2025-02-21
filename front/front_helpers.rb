# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

helpers do
  def partial(name, locals, opts = {})
    t = settings.zache.get("haml::#{name}") { Haml::Engine.new(File.read("views/_#{name}.haml")) }
    t.render(self, locals.merge(opts))
  end
end
