File.open("diagnostic_ana.txt", "w") do |f|
  prof = Profissional.where("nome LIKE '%ANA CAROLINA%'").first
  if prof
    f.puts "Professional: #{prof.nome} (ID: #{prof.id})"
    agendamentos = prof.agendamentos.where("dia_semana LIKE '%terça%'")
    f.puts "Total Tuesday Appointments in DB: #{agendamentos.count}"
    agendamentos.each do |ag|
      paciente_nome = ag.paciente&.nome || "N/A"
      f.puts "- Horario: #{ag.horario} | Paciente: #{paciente_nome} | Status: #{ag.status} | ID: #{ag.id}"
    end
  else
    f.puts "Professional not found"
  end
end
