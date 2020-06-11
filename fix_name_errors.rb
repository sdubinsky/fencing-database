require 'sequel'
require 'pry'
db_address = ENV["DATABASE_URL"] || "postgres://localhost/fencingstats"

def ask_for_canonical_name name, gfy
  puts "What's the correct name for #{name}(gfycat.com/#{gfy.gfycat_gfy_id})?"
  answer = gets.chomp
  if answer == 'skip'
    return
  end
  if answer == 'invalid'
    gfy.valid = false
    gfy.save
    return
  end
  CanonicalName.create(gfy_name: name, canonical_name: answer)
  get_correct_fencer answer, gfy
end

def get_correct_fencer name, gfy
  puts "Name: #{name} (gfycat.com/#{gfy.gfycat_gfy_id})"
  options = Fencer.find_name_possibilities(name, gfy.tournament.id).order_by(:first_name)
  options = options.where(gender: gfy.gender) if gfy.gender

  if options.count == 0
    puts "error: No matching fencers found for #{name}"
    return
  end
  if options.count == 1
    return options.first
  end
  return

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

  puts "name is nil for gfy #{gfy.gfycat_gfy_id}" unless name
  #canonical names are strictly for typos.  If the canonical version exists, it means
  #it doesn't exist in the fencer table.

  if CanonicalName.where(gfy_name: name).count == 1
    name = CanonicalName.first(gfy_name: name).canonical_name
  end
  options = Fencer.find_name_possibilities(name, gfy.tournament.id)
  
  options = options.where(gender: gfy.gender) if gfy.gender

  #If there are no matches, it's a typo of some kind.  This will set the canonical name
  if options.count == 0
    puts "no name found for #{name}"
    return
  elsif options.count == 1
    real_fencer = options.first
  else
    puts "too many names found for #{name}"
    return
  end
  return real_fencer
end

Sequel.connect db_address do |db|
  require './models/init'
  updated = 0
  Gfycat.where(bout_id: nil).where(left_fencer_id: nil, right_fencer_id: nil, valid: true).distinct(:fotl_name, :fotr_name, :tournament_id).each do |gfy|
    begin
      result = process_name gfy, :left
    rescue NoMethodError
      next
    end
    if result
      updated += 1
      gfy.update(left_fencer_id: result.id)
    end

    result = process_name gfy, :right
    if result
      updated += 1
      gfy.update(right_fencer_id: result.id)
    end
  end
  
  Gfycat.where(bout_id: nil).where(left_fencer_id: nil, valid: true).distinct(:fotl_name, :fotr_name, :tournament_id).each do |gfy|
    begin
      result = process_name gfy, :left
    rescue NoMethodError
      next
    end
    if result
      updated += 1
      gfy.update(left_fencer_id: result.id)
    end
  end

  Gfycat.where(bout_id: nil).where(right_fencer_id: nil, valid: true).distinct(:fotl_name, :fotr_name, :tournament_id).each do |gfy|
    begin
      result = process_name gfy, :right
    rescue NoMethodError
      next
    end
    if result
      updated += 1
      gfy.update(right_fencer_id: result.id)      
    end
  end
  puts "#{updated} updates made"
end
