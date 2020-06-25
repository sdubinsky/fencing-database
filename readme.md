# Fencing Database Site

## Adding new GFYs

1. Add the new tournament to the database.
2. Run `ruby ./update_gfycat_list.rb` and pipe it to the right psql.
3. run the rake tasks `db:normalize_names` and `db:add_bouts`.
4. Run the `fix_name_errors` script, alternating with the rake task `db:add_bouts` until it stabilizes.

## To update the heroku db

1. dump the db by running `pg_dump --inserts --no-owner fencingstats > dump.dump`
2. upload it to heroku by running `heroku pg:psql < dump.dump`

## To dump the heroku db

1. Create a backup: `heroku pg:backups:capture`
2. Download the backup: `heroku pg:backups:download`
3. load the data in the the local database: `pg_restore --verbose --clean --no-acl --no-owner -d fencingstats latest.dump`

## To add a new list of entries for a tournament:
1. Make sure the `download_tournament_entries.rb` file is set up to take arguments in stead of processing the list
2. Run the command and pipe it to psql locally, to make sure it's accurate.
3. Pipe it to heroku psql

## To update the gfycat list:
1. run the `update_gfycat_list.rb` file and pipe it to `heroku psql`.
