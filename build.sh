#!/bin/bash
tag=${RANDOM}-$(date +%F)
docker build -t qnib/www:${tag} --target=build .
docker run -ti --rm -v $(pwd):/data qnib/www:${tag} \
     rsync -aP --delete /opt/jekyll/_site/. /data/_site/.