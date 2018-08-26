Sequel.migration do
  up do
    add_column :gfycats, :left_fencer_id, Integer
    add_column :gfycats, :right_fencer_id, Integer
  end

  down do
    drop_column :gfycats, :left_fencer_id
    drop_column :gfycats, :right_fencer_id
  end
end
