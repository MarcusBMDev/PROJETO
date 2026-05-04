File.open("deep_diagnostic.txt", "w") do |f|
  f.puts "CHECKING ANA CAROLINA"
  prof = Profissional.where("nome LIKE '%ANA CAROLINA%'").first
  if prof
    ag_data = prof.agendamentos.pluck(:horario, :dia_semana, :status, :paciente_id, :id)
    terca_ag = ag_data.select { |o| o[1].to_s.upcase.strip == "TERÇA-FEIRA" }
    f.puts "Appointments in DB for Tuesday: #{terca_ag.size}"
    terca_ag.each do |ag|
      p = Paciente.find_by(id: ag[3])
      f.puts "- ID: #{ag[4]} | Time: #{ag[0]} | Status: #{ag[2]} | Patient: #{p&.nome}"
    end
    
    # Simulate processar_vagas
    ctrl = Api::AgendamentosController.new
    vagas = ctrl.send(:processar_vagas, ClinicSlots::STANDARD, terca_ag)
    f.puts "Calculated Vacancies: #{vagas.inspect} (#{vagas.size})"
  else
    f.puts "Ana Carolina not found"
  end

  f.puts "\nCHECKING DAYANE"
  prof_d = Profissional.where("nome LIKE '%DAYANE%'").first
  if prof_d
    ag_d = prof_d.agendamentos.pluck(:horario, :dia_semana, :status, :paciente_id, :id)
    terca_d = ag_d.select { |o| o[1].to_s.upcase.strip == "TERÇA-FEIRA" }
    f.puts "Appointments in DB for Tuesday: #{terca_d.size}"
    terca_d.each do |ag|
      p = Paciente.find_by(id: ag[3])
      f.puts "- ID: #{ag[4]} | Time: #{ag[0]} | Status: #{ag[2]} | Patient: #{p&.nome}"
    end
    vagas_d = ctrl.send(:processar_vagas, ClinicSlots::STANDARD, terca_d)
    f.puts "Calculated Vacancies: #{vagas_d.inspect} (#{vagas_d.size})"
  end
end
