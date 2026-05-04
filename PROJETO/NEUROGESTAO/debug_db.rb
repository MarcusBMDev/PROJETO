File.open("debug_db_out.txt", "w") do |f|
  Profissional.where("nome LIKE '%ANA CAROLINA%' OR nome LIKE '%DAYANE%'").each do |prof|
    f.puts "---#{prof.nome}---"
    agendamentos = prof.agendamentos.where("dia_semana LIKE '%TERÇA%'")
    f.puts "TERÇA: #{agendamentos.pluck(:horario, :dia_semana).inspect}"
  end
end
