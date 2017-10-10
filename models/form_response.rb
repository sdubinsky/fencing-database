require 'pry'
class FormResponse < Sequel::Model
  many_to_one :gfycat
  def self.total
    FormResponse.all.count
  end

  def self.most_popular_location filters
    query = DB[:gfycats].select(:id)
    if filters[:tournament] and filters[:tournament] != "all"
      query = DB[:gfycats].where(tournament: filters[:tournament]).select(:id)
    end
    ret = query.join(:form_responses, stats_id: :id).select(:strip_location).group_and_count(:strip_location).limit(1).first
    puts ret.to_s
    ret
  end

  def self.most_popular_hit filters = {}
    DB["select body_location, count(body_location) as total from form_responses group by body_location order by total desc limit 1;"].first
  end
end
