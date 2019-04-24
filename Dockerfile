FROM ruby:2.6-alpine

# set the timezone appropriatlyENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# set the locale correctly
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apk update && apk add --update-cache nodejs nodejs-npm sqlite-dev \
  build-base linux-headers yarn tzdata \
  && rm -rf /var/cache/apk/*

# create the work directory
ENV APP_HOME /orcid_connector
ENV RAILS_ENV='production'
ENV NODE_ENV='production'
WORKDIR $APP_HOME

# Create the run user and group
RUN addgroup -g 18570 sse && adduser -G sse -u 1985 -D docker

COPY Gemfile Gemfile.lock package.json yarn.lock ./
RUN bundle install --jobs=4 --without=["development" "test"] --no-cache

# copy the application
ADD . $APP_HOME

# workaround for yarn issue
RUN npm rebuild node-sass
RUN SECRET_KEY_BASE=x bundle exec rails assets:precompile

# Update permissions
RUN chown -R docker $APP_HOME && chgrp -R sse $APP_HOME
# Set user
USER docker

EXPOSE 3000
CMD scripts/entry.sh
