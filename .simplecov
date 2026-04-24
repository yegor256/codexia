# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2020-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

SimpleCov.formatter = if Gem.win_platform?
                        SimpleCov::Formatter::MultiFormatter[
                          SimpleCov::Formatter::HTMLFormatter
                        ]
                      else
                        SimpleCov::Formatter::MultiFormatter.new(
                          [SimpleCov::Formatter::HTMLFormatter]
                        )
                      end
SimpleCov.configure do
  add_filter '/test/'
  add_filter '/features/'
end
