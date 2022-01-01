# Heimdallr

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/heimdallr`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'heimdallr'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install heimdallr

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Running with limited "intents"/privileges

By default, the bot runs with all "intents" (privileges to see certain things about the Discord server) enabled.
This only works if your bot registration has these intents enabled.
If you wish to run the bot with limited intents so you don't have to enable any for your bot registration, look for the following line in `lib/heimdallr.rb`:

```ruby
  bot = Discordrb::Commands::CommandBot.new token: ENV["DISCORD_BOT_TOKEN"], prefix: ","
```

And add the `intents` option, like for example:

```ruby
  bot = Discordrb::Commands::CommandBot.new token: ENV["DISCORD_BOT_TOKEN"], prefix: ",", intents: [:servers, :server_messages]
```

Please note that some of the bot's functionality relies on some intents not enabled on your bot registration by default, and will no longer work if you de-privilege your bot to these intents.
The most likely functionality to be unavailable in this case is the welcome/leave messages.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/heimdallr. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/heimdallr/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Heimdallr project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/heimdallr/blob/master/CODE_OF_CONDUCT.md).
