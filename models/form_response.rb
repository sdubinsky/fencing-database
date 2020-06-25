require 'pry'
class FormResponse < Sequel::Model
  many_to_one :gfycat
  def self.total filters = {}
    query = build_query filters
    query.count 
  end

  def self.most_popular_location filters = {} 
    query = build_query filters
    ret = query.select(:strip_location).group_and_count(:strip_location).reverse(:count).limit(1).first
    ret ||= {strip_location: "unknown part", count: 0}
    ret[:strip_location] ||= "unknown part"
    ret
  end

  def self.most_popular_hit filters = {}
    
    DB["select body_location, count(body_location) as total from form_responses group by body_location order by total desc limit 1;"].first
  end
  
  def self.heatmap_colors filters = {}
    colors = {}
    heatmap_colors = ['#FFFFFF', '#FFE9E9', '#FFCCCC', '#FF9999', '#FF6666', '#FF3333', '#FF0000', '#CC0000', '#990000', '#660000', '#330000']
    query = build_query filters
    query = query.select(:strip_location).group_and_count(:strip_location)
    total = query.reduce(0){|t, c| t + c[:count]}
    query.each do |location|
      colors[location[:strip_location]] = heatmap_colors[(location[:count].to_f / total * 10).to_i]
    end
    colors
  end

  def self.build_query filters = {}
    query = DB[:gfycats]
    query = query.join(:form_responses, stats_id: :gfycat_gfy_id)
    if filters[:tournament] and filters[:tournament] != "all"
      query = query.where(tournament_id: filters[:tournament])
    end
    if filters[:fencer_name] and filters[:fencer_name] != "all"
      query = query.where{Sequel.|({fotl_name: filters[:fencer_name]}, {fotr_name: filters[:fencer_name]})}
    end
    if filters[:weapon] and filters[:weapon] != 'all'
      query = query.where(weapon: filters[:weapon])
    end
    if filters[:gender] and filters[:gender] != 'all'
      query = query.where(Sequel.|({gender: filters[:gender]}, {gender: nil}))
    end
    query
  end
end
