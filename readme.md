# Fencing Database Site

## Adding new GFYs

1. Add the new tournament to the database.
2. Download the entries via `ruby download_tournament_entries.rb`
2. Run `ruby ./update_gfycat_list.rb` and pipe it to the right psql.
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
* on heroku: DATABASE_URL=`heroku config:get DATABASE_URL -a fencing-db` ruby download_tournament_entries.rb

## To update the gfycat list:
1. run the `update_gfycat_list.rb` file and pipe it to `heroku psql`.
