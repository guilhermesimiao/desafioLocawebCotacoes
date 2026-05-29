FROM ruby:3.2

RUN apt-get update -qq && apt-get install -y build-essential ca-certificates

WORKDIR /app

COPY Gemfile ./

RUN echo ":ssl_verify_mode: 0" >> ~/.gemrc && \
    bundle config set --global ssl_verify_mode 0 && \
    bundle config set --global jobs 4 && \
    bundle config set --global retry 3 && \
    bundle install

COPY . .
EXPOSE 4567
CMD ["ruby", "app.rb"]