f1 = File.open("fencers_names/all_fencers.html", 'rb')
f2 = File.open("fencers_names/fencers_sanitized.html", 'w')

f1.each.select{|a| a.include? "<td>"}.each do |line|
  l2 = line.gsub(/<.*?>/, ",").sub(/(\s.[a-z])/, ',\1').gsub(",,", ",").gsub(",,", ",").gsub(",\n", "\n").gsub(/\A,/, "").gsub(", ", ",").gsub(",", "','").strip
  f2.puts "('#{l2}'),"
end
