File.open("vacancy_debug_ana.txt", "w") do |f|
  prof = Profissional.find(3)
  f.puts "PROF: #{prof.nome} (ID: #{prof.id})"
  
  ag_data = prof.agendamentos.pluck(:horario, :dia_semana, :status)
  f.puts "Raw Agendamentos (Sample): #{ag_data.first(3).inspect}"
  
  # Simulate AgendamentosController context
  ctrl = Api::AgendamentosController.new
  
  slots_pad = ClinicSlots::STANDARD # ["08:00", ...]
  
  # Check Tuesday specifically
  terca_ag = ag_data.select { |o| o[1].to_s.strip.upcase == "TERÇA-FEIRA" }
  f.puts "Tuesday Agendamentos Count: #{terca_ag.size}"
  terca_ag.each {|a| f.puts "  - #{a.inspect} | Bytes: #{a[0].to_s.bytes.inspect}" }
  
  # Run processar_vagas
  vagas = ctrl.send(:processar_vagas, slots_pad, terca_ag)
  f.puts "\nRESULTING VACANCIES FOR TUESDAY:"
  f.puts vagas.inspect
  f.puts "Total: #{vagas.size}"
end
