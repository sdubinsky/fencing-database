require 'sequel'

db_address = ENV["DATABASE_URL"] || "postgres://localhost/fencingstats"

def ask_for_fencer name, gfy
  puts "What's the correct name for #{name}(gfycat.com/#{gfy.gfycat_gfy_id})?"
  answer = gets.chomp
  get_canonical_name answer, gfy
end

def get_canonical_name name, gfy
  puts "Name: #{name} (gfycat.com/#{gfy.gfycat_gfy_id})"
  options = Fencer.find_name_possibilities(name).order_by(:first_name)
  options = options.where(gender: gfy.gender) if gfy.gender
  if options.count == 0
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

Sequel.connect db_address do |db|
  require './models/init'
  Gfycat.where(bout_id: nil).where(left_fencer_id: nil, valid: true).distinct(:fotl_name, :tournament_id).each do |gfy|
    #If there's no name to be found, it's probably misspelled
    options = Fencer.find_name_possibilities(gfy.fotl_name)
    options = options.where(gender: gfy.gender) if gfy.gender
    if options.count == 0
      if CanonicalName.first(gfy_name: gfy.fotl_name)
        gfy.update(left_fencer_id: CanonicalName.first(gfy_name: gfy.fotl_name).fencer_id)
      else
        real_fencer = ask_for_fencer gfy.fotl_name, gfy
        if real_fencer
          gfy.update(left_fencer_id: real_fencer.id)
          CanonicalName.create(gfy_name: gfy.fotl_name, fencer_id: real_fencer.id).save
        end
      end
    elsif options.count == 1
      gfy.update(left_fencer_id: options.first.id)
    else
      name = get_canonical_name gfy.fotl_name, gfy
      gfy.update(left_fencer_id: name.id) if name
    end
  end

    Gfycat.where(bout_id: nil).where(right_fencer_id: nil, valid: true).distinct(:fotr_name, :tournament_id).each do |gfy|
    #If there's no name to be found, it's probably misspelled
    options = Fencer.find_name_possibilities(gfy.fotr_name)
    options = options.where(gender: gfy.gender) if gfy.gender
    if options.count == 0
      if CanonicalName.first(gfy_name: gfy.fotr_name)
        gfy.update(right_fencer_id: CanonicalName.first(gfy_name: gfy.fotr_name).fencer_id)
      else
        real_fencer = ask_for_fencer gfy.fotr_name, gfy
        if real_fencer
          gfy.update(right_fencer_id: real_fencer.id)
          CanonicalName.create(gfy_name: gfy.fotr_name, fencer_id: real_fencer.id).save
        end
      end
    elsif options.count == 1
      gfy.update(right_fencer_id: options.first.id)
    else
      name = get_canonical_name gfy.fotr_name, gfy
      gfy.update(right_fencer_id: name.id) if name
    end
  end

  
end
