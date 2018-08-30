f1 = File.open("fencers_names/all_fencers.html", 'rb')
f2 = File.open("fencers_names/fencers.sql", 'w')
f2.puts "insert into fencers (last_name, first_name, nationality, birthday, gender) values"
f1.each.select{|a| a.include? "<td>"}.each do |line|
  l2 = line.gsub(/<.*?>/, ",").sub(/(\s.[^A-Z])/, ',\1').gsub(",,", ",").gsub(",,", ",").gsub(",\n", "\n").gsub(/\A,/, "").gsub(", ", ",").gsub(",", "','").gsub("&nbsp;", "").strip
  f2.puts "('#{l2}'),"
end
