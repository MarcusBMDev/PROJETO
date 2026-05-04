File.open("full_week_ana.txt", "w") do |f|
  prof = Profissional.where("nome LIKE '%ANA CAROLINA%'").first
  if prof
    f.puts "ANA CAROLINA - ID: #{prof.id}"
    prof.agendamentos.order(:dia_semana, :horario).each do |ag|
      f.puts "- Day: #{ag.dia_semana} | Time: #{ag.horario} | Patient: #{ag.paciente&.nome}"
    end
  end
end
