FROM jekyll/jekyll AS build
RUN gem install redcarpet
WORKDIR /opt/jekyll
COPY . .
USER root
RUN rm -rf /opt/jekyll/_site \
 && mkdir -p /opt/jekyll/_site
RUN jekyll build 

FROM qnib/plain-caddy:2019-05-19
COPY --from=build /opt/jekyll/_site /srv
