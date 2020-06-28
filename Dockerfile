FROM ruby:2

ARG USERNAME=heimdallr
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME
RUN useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME


# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY . .
RUN bundle install

RUN chown -R $USERNAME .

USER $USERNAME

ENTRYPOINT ["/usr/local/bin/bundle", "exec", "bot.rb"]
