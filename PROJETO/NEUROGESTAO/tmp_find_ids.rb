
require_relative 'config/environment'

puts "START_RESULTS"
begin
  group = NeurochatRecord.connection.select_one("SELECT id, name FROM groups WHERE name LIKE '%AGENDAMENTO PSICONEURO%'")
  if group
    puts "GROUP_ID|#{group['id']}"
    puts "GROUP_NAME|#{group['name']}"
  else
    puts "GROUP_NOT_FOUND"
  end

  user = NeurochatRecord.connection.select_one("SELECT id, username FROM users WHERE username = 'Marcus TI' OR id = 1")
  if user
    puts "USER_ID|#{user['id']}"
    puts "USER_NAME|#{user['username']}"
  else
    puts "USER_NOT_FOUND"
  end
rescue => e
  puts "ERROR|#{e.message}"
end
puts "END_RESULTS"
