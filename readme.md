# Fencing Database Site

## Local Set Up

1. Install a ruby version between 2.5 and 3.
2. `bundle install`
3. Install postgres, if you haven't already, and create yourself a database.
3. Create a config.yml file in the app root dir.  You need a `db` key with the following subkeys:
   1. `db_name`
   2. `db_address`
   3. `db_username`
   4. `db_password`
4. Run the migrations: `rake db:migrate`
5. Add the tournaments.  `download_tournament_entries.rb` has the list of tournament keys.
6. Add the GFYs to the DB as below.
7. If you have any questions, open a ticket or email me. 

## Adding new GFYs

1. Add the new tournament to the database.
2. Download the entries via `ruby download_tournament_entries.rb`
2. Run `ruby ./update_gfycat_list.rb`.
   3. Locally, just run the script and it'll use whatever is in your `config.yml`
   4. to update heroku, prepend it with DATABASE_URL=`heroku config:get DATABASE_URL -a fencing-db`
3. run the rake tasks `db:normalize_names` and `db:add_bouts`.

This section is also a rake task named `db:update_gfycats` but that probably won't work on heroku.

## To update the heroku db

1. dump the db by running `pg_dump -c --no-owner fencingstats > dump.dump`
2. upload it to heroku by running `heroku pg:psql < dump.dump`

## To dump the heroku db

1. Create a backup: `heroku pg:backups:capture`
2. Download the backup: `heroku pg:backups:download`
3. load the data in the the local database: `pg_restore --verbose --clean --no-acl --no-owner -d fencingstats latest.dump`

## To add a new list of entries for a tournament:
* Find the tournament on the fie page, click "entries".
* add the entries page(s) to the hash in `download_tournament_entries.rb'.`
* locally: `ruby download_tournament_entries.rb`
* on heroku: DATABASE_URL=`heroku config:get DATABASE_URL -a fencing-db` ruby `download_tournament_entries.rb`
