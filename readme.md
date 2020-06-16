# Fencing Database Site

## Adding new GFYs

1. Add the new tournament to the database.
2. Run `rake db:update_gfycat_list`
3. run the rake tasks `db:normalize_names` and `db:add_bouts`.
4. Run the `fix_name_errors` script, alternating with the rake task `db:add_bouts` until it stabilizes.

## To update the heroku db

1. dump the db by running `pg_dump --inserts --no-owner fencingstats > dump.dump`
2. upload it to heroku by running `heroku pg:psql < dump.dump`

## To add a new list of entries for a tournament:
1. Make sure the `download_tournament_entries.rb` file is set up to take arguments in stead of processing the list
2. Run the command and pipe it to psql locally, to make sure it's accurate.
3. Pipe it to heroku psql

## To update the gfycat list:
1. run the `update_gfycat_list.rb` file and pipe it to `heroku psql`.
