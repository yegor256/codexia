<img src="http://www.codexia.org/logo.svg" height="96px"/>

[![EO principles respected here](https://www.elegantobjects.org/badge.svg)](https://www.elegantobjects.org)
[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/codexia)](http://www.rultor.com/p/yegor256/codexia)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![Build Status](https://travis-ci.org/yegor256/codexia.svg?branch=master)](https://travis-ci.org/yegor256/codexia)
[![PDD status](http://www.0pdd.com/svg?name=yegor256/codexia)](http://www.0pdd.com/p?name=yegor256/codexia)
[![codecov](https://codecov.io/gh/yegor256/codexia/branch/master/graph/badge.svg)](https://codecov.io/gh/yegor256/codexia)
[![Maintainability](https://api.codeclimate.com/v1/badges/b84839a6064ac08ba41c/maintainability)](https://codeclimate.com/github/yegor256/codexia/maintainability)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yegor256/takes/codexia/master/LICENSE.txt)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/codexia)](https://hitsofcode.com/view/github/yegor256/codexia)

Codexia is an open source incubator. We want to build
a community of reviewers and advisers to help us select the most
interesting _emerging_ open source projects. According to
the selection made by the community we want to donate
our funds to the most promising teams and projects.

Read our [Terms of Use](https://www.codexia.org/terms).

We have the following official bots at the moment:

  * [codexia-bot](https://github.com/iakunin/codexia-bot)
    by [@iakunin](https://github.com/iakunin)
    as [@iakunin-codexia-bot](https://github.com/iakunin-codexia-bot)

  * [codexia-hunter](https://github.com/fellahi-ali/codexia-hunter)
    by [@fellahi-ali](https://github.com/fellahi-ali)
    as [@codexia-hunter](https://github.com/codexia-hunter)

If you want to add yours, join our
[Telegram group](https://t.me/cdxia) and suggest it.

## How to contribute

Read [these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure your build is green before you contribute
your pull request. You will need to have [Ruby](https://www.ruby-lang.org/en/) 2.3+,
Java 8+, Maven 3.2+, PostgreSQL 10+, and
[Bundler](https://bundler.io/) installed. Then:

```bash
$ bundle update
$ bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.

To run a single unit test you should first do this:

```bash
$ bundle exec rake run
```

And then, in another terminal (for example):

```bash
$ ruby test/test_risks.rb -n test_adds_and_fetches
```

If you want to test it in your browser, open `http://localhost:9292`. If you
want to login as a test user, just open this: `http://localhost:9292?glogin=test`.

Should work.
