FROM abiosoft/caddy

COPY _site /www/site
COPY Caddyfile /etc/
