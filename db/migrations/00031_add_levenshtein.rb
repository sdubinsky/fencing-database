Sequel.migration do
  up do
    run 'create extension fuzzystrmatch'
  end

  down do
    run 'drop extension fuzzystrmatch'
  end
end
