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
RUN bundle install

COPY bin/entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE  3000

CMD ["rails", "server", "-b", "0.0.0.0"]
