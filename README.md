<img src="http://www.codexia.org/logo.svg" height="96px"/>

Codexia is an open source incubator. We want to build
a community of reviewers and advisers to help us select the most
interesting emerging open source projects. According to
the selection made by the community we want to donate
our funds to the most promising teams and projects.

[![Build Status](https://travis-ci.org/yegor256/codexia.svg?branch=master)](https://travis-ci.org/yegor256/codexia
)
[![codecov](https://codecov.io/gh/yegor256/codexia/branch/master/graph/badge.svg)](https://codecov.io/gh/yegor256/codexia)

## How it works?

Any open source _project_ can be added to the list.

Each project may get either manual or automated _reviews_ (via API).

A review can be _voted_ (up or down) by a user.

Users have _reputations_, which depend on
1) the amount of votes their reviews collected,
2) the amount of reviews they posted, and
3) the amount of projects they submitted.

Projects may get and lose _badges_, according to some rules. For example,
if a project has a review which is less than 6 months old and
has more than 100 upvotes, the badge `trending` gets attached.

Certain _features_ may be available only for users with big
enough reputation, for example older reviews may be visible
only by more reputable users.

Users may _sell_ their reputation to us.

## Build and Run the project (you need postgres locally)

```bash
npm i
npm run build
npm run local
```

## Check postgresql connection:

[http://localhost:8000/postgres](http://localhost:8000/postgres)
