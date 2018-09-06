require 'sequel'

db_address = ENV["DATABASE_URL"] || "postgres://localhost/fencingstats"

def ask_for_canonical_name name, gfy
  puts "What's the correct name for #{name}(gfycat.com/#{gfy.gfycat_gfy_id})?"
  answer = gets.chomp
  CanonicalName.create(gfy_name: name, canonical_name: answer)
  get_correct_fencer answer, gfy
end

def get_correct_fencer name, gfy
  puts "Name: #{name} (gfycat.com/#{gfy.gfycat_gfy_id})"
  options = Fencer.find_name_possibilities(name).order_by(:first_name)
  options = options.where(gender: gfy.gender) if gfy.gender

  if options.count == 0
    puts "error: No matching fencers found for #{name}"
    return
  end
  if options.count == 1
    return options.first
  end
  options.each_with_index do |option, i|
    puts "#{i}. #{option.name} (#{option.gender}, #{option.nationality})"
  end
  answer = gets.chomp
  if answer == 'skip'
    return
  end
  options.all[answer.to_i]
end

def process_name gfy, side
  if side == :left
    fencer_id = :left_fencer_id
    name = gfy.fotl_name
  elsif side == :right
    fencer_id = :right_fencer_id
    name = gfy.fotr_name
  end
  #canonical names are strictly for typos.  If the canonical version exists, it means
  #it doesn't exist in the fencer table.
  if CanonicalName.where(gfy_name: name).exists?
    options = Fencer.find_name_possibilities(CanonicalName.first(gfy_name: name).canonical_name)
  else
    options = Fencer.find_name_possibilities(gfy.name)
  end
  options = options.where(gender: gfy.gender) if gfy.gender

  #If there are no matches, it's a typo of some kind.  This will set the canonical name
  if options.count == 0
    real_fencer = ask_for_canonical_name name, gfy
  elsif options.count == 1
    real_fencer = options.first
  else
    real_fencer = get_correct_fencer name, gfy
  end
  return real_fencer
end

Sequel.connect db_address do |db|
  require './models/init'
  Gfycat.where(bout_id: nil).where(left_fencer_id: nil, valid: true).distinct(:fotl_name, :tournament_id).each do |gfy|
    result = process_name gfy, :left
    gfy.update(left_fencer_id: result.id)
  end

  Gfycat.where(bout_id: nil).where(right_fencer_id: nil, valid: true).distinct(:fotr_name, :tournament_id).each do |gfy|
    result = process_name gfy, :right
    gfy.update(right_fencer_id: result.id)
  end

  
end
