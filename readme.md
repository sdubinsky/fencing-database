# Fencing Database Site

## Adding new GFYs

1. Add the new tournament to the database.
2. start the site, send a get request to `/update_gfycat_list`.  Or, rake task `db:update_gfycat_list`
3. run the rake tasks `db:normalize_names` and `db:add_bouts`.
4. Run the `fix_name_errors` script, alternating with the rake task `db:add_bouts` until it stabilizes.  Note that 

## To update the heroku db

1. dump the db by running `pg_dump --no-owner fencingstats > dump.dump`
2. upload it to heroku by running `heroku pg:psql < dump.dump`
