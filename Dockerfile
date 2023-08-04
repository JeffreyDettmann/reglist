FROM ruby:3.1.4-slim-bullseye AS app

WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential curl libpq-dev postgresql-client netcat

RUN curl -sL https://deb.nodesource.com/setup_16.x -o /tmp/nodesource_setup.sh && bash /tmp/nodesource_setup.sh

RUN apt-get install nodejs

RUN npm install --global yarn

RUN yarn add @hotwired/turbo-rails
RUN yarn add @hotwired/stimulus

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install --without development test

RUN mkdir /app/log
COPY config.ru /app/config.ru
COPY bin /app/bin
COPY lib /app/lib
COPY Rakefile /app/Rakefile
COPY storage /app/storage
COPY Gemfile /app/
COPY Gemfile.lock /app/
COPY package.json /app/
COPY yarn.lock /app/
COPY app/assets /app/app/assets
COPY public /app/public
COPY db /app/db
COPY config /app/config
COPY app/javascript /app/app/javascript
COPY app/models /app/app/models
COPY app/helpers /app/app/helpers
COPY app/controllers /app/app/controllers
COPY app/views /app/app/views

RUN rails assets:precompile

COPY bin/entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE  3000

CMD ["rails", "server", "-b", "0.0.0.0"]
