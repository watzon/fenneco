<div align="center">
  <img src="./assets/fenneco.png" alt="term logo">
</div>

# Fenneco - Telegram Userbot

Fenneco is a Telegram userbot which uses [proton](https://github.com/watzon/proton), a very much WIP Telegram client API library built on top of [tdlib](https://github.com/tdlib/td).

Fenneco is still very much in development and will be undergoing many changes, so keep posted.

## Dependencies

Fenneco makes use of [proton](https://github.com/protoncr/proton) for connecting with the telegram client API. Proton requires libtdjson 1.6.4 (the most recent version at the time of writing). It's advised to build it yourself. Proton is written in Crystal as well (in case that wasn't obvious), as is Fenneco, so you will need Crystal installed in order to build.

Proton also depends on libmagic for filetype detection. You should be able to find an installable version on most systems. Make sure you have the `-dev` or `-devel` version.

You will also need a postgresql database.

## Installation

1. Fork or clone this code. Alternatively you can also download a zipped version of it [here](https://github.com/watzon/fenneco/archive/master.zip).

2. Inside of the `fenneco` directory, run `shards install` to install dependencies.

3. Once dependencies are installed you'll need to copy `.env.example` to `.env` and modify the values inside. The most important things are `API_ID`, `API_HASH`, and `DB_URI`. You can find your api id and api hash at https://my.telegram.org. The `DB_URI` will need to be a URI for your postgres database using the format postgres://username:password@host/database. Also potentially important is `TD_DATABASE_DIRECTORY` which is the path at which the tdlib database will be stored.

4. Now it's time to migrate the database. You can do that using micrate. Just run `./micrate up` in the root of the project. If your database credentials were entered correctly into your `.env` file you should see success messages.

5. Finally it's time to run fenneco. Use the command `crystal run ./src/fenneco.cr`. If everything was done correctly you should see some connection stats (output by tdlib) and it should ask for your phone number. You should only need to do this once (unless you change the `TD_DATABASE_DIRECTORY` value).

That should be about it. Go to Telegram, enter `.stats`, press enter, and you should see some statistics about your bot. If you want to enable multithreading (which is advised) run `crystal run` with the `-Dpreview_mt` flag.

## Extras

There are some extra values that can be provided inside of your `.env` file, but aren't required. Here they are:

- `LOG_CHAT_ID` - This is used for logging and is still in the works. Provide a chat in which you have permission to send messages and all logs will be output there.
- `LOG_CHAT_INVITE_LINK` - If you want your log chat to be joinable by others you can include the invite link here. It will show up when you use the `.stats` command.
- `SPAMWATCH_TOKEN` - API key for the [SpamWatch API](https://api.spamwat.ch)
- `DOGBIN_API_KEY` - API key for https://del.dog. This allows pastes to be attached to your account.
- `GOOGLE_AUTH_FILE` - A JSON file containing credentials for Google APIs. For now all that is needed is an account that has access to the translation API.

## Contributing

1. Fork it (<https://github.com/watzon/fenneco/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [watzon](https://github.com/watzon) - creator and maintainer
