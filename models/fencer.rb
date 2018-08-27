require 'pry'
class Fencer < Sequel::Model
  def name
    self.last_name.split.map{|a| a.capitalize}.join(" ") + ", " + self.first_name.split.map{|a| a.capitalize}.join(" ")
  end
end
