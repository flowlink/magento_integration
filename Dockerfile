FROM ruby:2.4.2-slim-stretch
MAINTAINER Ric Lister <ric@spreecommerce.com>

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -yq \
    build-essential \
    zlib1g-dev libreadline6-dev libyaml-dev libssl-dev \
    git

## help docker cache bundle
WORKDIR /tmp
ADD ./Gemfile /tmp/
ADD ./Gemfile.lock /tmp/

RUN bundle install

WORKDIR /app
ADD ./ /app

EXPOSE 5000

ENTRYPOINT [ "bundle", "exec" ]
CMD [ "foreman", "start" ]
