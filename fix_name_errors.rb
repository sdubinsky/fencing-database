require 'sequel'

db_address = ENV["DATABASE_URL"] || "postgres://localhost/fencingstats"

def ask_for_fencer name, gfy_id
  puts "What's the correct name for #{name}(#{gfy_id})?"
  answer = gets.chomp
  get_canonical_name answer, gfy_id
end

def get_canonical_name name, gfy_id
  puts "Name: #{name} (#{gfy_id})"
  options = Fencer.find_name_possibilities(name).order_by(:first_name)
  if options.count == 1
    return options.first
  end
  options.each_with_index do |option, i|
    puts "#{i}. #{option.name}"
  end
  answer = gets.chomp
  if answer == 'skip'
    return
  end
  options.all[answer.to_i]
end

Sequel.connect db_address do |db|
  require './models/init'
  Gfycat.where(bout_id: nil).where(left_fencer_id: nil, valid: true).distinct(:fotl_name, :tournament_id).each do |gfy|
    #If there's no name to be found, it's probably misspelled
    if Fencer.find_name_possibilities(gfy.fotl_name).count == 0
      if CanonicalName.first(gfy_name: gfy.fotl_name)
        gfy.update(left_fencer_id: CanonicalName.first(gfy_name: gfy.fotl_name).fencer_id)
      else
        real_fencer = ask_for_fencer gfy.fotl_name, gfy.gfycat_gfy_id
        if real_fencer
          gfy.update(left_fencer_id: real_fencer.id)
          CanonicalName.create(gfy_name: gfy.fotl_name, fencer_id: real_fencer.id).save
        end
      end
    elsif Fencer.find_name_possibilities(gfy.fotl_name).count == 1
      gfy.update(left_fencer_id: Fencer.find_name_possibilities(gfy.fotl_name).first.id)
    else
      name = get_canonical_name gfy.fotl_name, gfy.gfycat_gfy_id
      gfy.update(left_fencer_id: name.id) if name
    end
  end
end
