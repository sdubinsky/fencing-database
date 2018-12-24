# Fencing Database Site

## Adding new GFYs

1. start the site, send a get request to `/update_gfycat_list`.  Or, rake task `db:update_gfycat_list`
2. run the rake tasks `db:normalize_names` and `db:add_bouts`.
3. Run the `fix_name_errors` script, alternating with the rake task `db:add_bouts` until it stabilizes.  Note that 
