# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'xia'

# JSON-ed object.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2020-2025 Yegor Bugayenko
# License:: MIT
class Xia::Sieve
  def initialize(origin, *methods)
    @origin = origin
    @methods = methods
  end

  def to_json(options = nil)
    return @origin.to_a.to_json(options) if @methods.count(1) && @methods[0] == :to_a
    @methods.map { |j| [j, __send__(j)] }.to_h.to_json(options)
  end

  def to_s
    'Sieve:' + method_missing(:to_s)
  end

  def method_missing(*args)
    method = args[0]
    raise "Method #{method} is absent in #{@origin}" unless @origin.respond_to?(method)
    @origin.__send__(*args) do |*a|
      yield(*a) if block_given?
    end
  end

  def respond_to?(method, include_private = false)
    @origin.respond_to?(method, include_private)
  end

  def respond_to_missing?(_method, _include_private = false)
    true
  end
end
