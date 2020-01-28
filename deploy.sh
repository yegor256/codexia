#!/bin/bash
set -e

cd $(dirname $0)
npm install
npm run build
cp /code/home/assets/codexia/prod.json resources/prod.json
git add resources/prod.json
git commit -m 'resources/prod.json for dokku'
trap 'git reset HEAD~1 && rm resources/prod.json && git checkout -- .gitignore' EXIT
git push dokku master -f

