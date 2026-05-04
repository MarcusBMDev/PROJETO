File.open("debug_ana_full.txt", "w") do |f|
  prof = Profissional.where("nome LIKE '%ANA CAROLINA%'").first
  if prof
    ["SEGUNDA", "TERCA", "TERÇA", "QUARTA", "QUINTA", "SEXTA"].each do |dia|
      f.puts "=== #{dia} ==="
      prof.agendamentos.where("dia_semana LIKE ?", "%#{dia}%").order(:horario).each do |ag|
        nome_paciente = ag.paciente ? ag.paciente.nome : "Desconhecido"
        f.puts "#{ag.horario} - #{nome_paciente} (#{ag.dia_semana})"
      end
    end
  else
    f.puts "Prof. nao achada"
  end
end
