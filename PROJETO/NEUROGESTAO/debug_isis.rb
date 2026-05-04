File.open("debug_isis.txt", "w") do |f|
  ag = Agendamento.joins(:paciente).where("pacientes.nome LIKE '%ISIS PINHEIRO%'").first
  if ag
    f.puts "Horario: #{ag.horario}"
    f.puts "Dia: #{ag.dia_semana}"
    f.puts "Profissional: #{ag.profissional.nome}"
    f.puts "Status: #{ag.status}"
  else
    f.puts "Nao Encontrada"
  end
end
