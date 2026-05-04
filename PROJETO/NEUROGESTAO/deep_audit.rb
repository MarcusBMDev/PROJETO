File.open("deep_audit_ana.txt", "w") do |f|
  f.puts "--- PROFS NAMED ANA CAROLINA ---"
  profs = Profissional.where("nome LIKE ?", "%ANA CAROLINA%")
  f.puts "Count: #{profs.size}"
  profs.each do |p|
    f.puts "ID: #{p.id} | Name: [#{p.nome}] | Specs: #{p.especialidade} | Active: #{p.ativo}"
    ag_count = p.agendamentos.count
    f.puts "  Appointments: #{ag_count}"
    if ag_count > 0
      p.agendamentos.limit(5).each do |ag|
        f.puts "    - #{ag.dia_semana} #{ag.horario} | Patient: #{ag.paciente&.nome}"
      end
    end
  end

  f.puts "\n--- ALL APPOINTMENTS WITH PROFS CONTAINING 'ANA' ---"
  Agendamento.joins(:profissional).where("profissionais.nome LIKE ?", "%ANA%").group("profissionais.id", "profissionais.nome").count.each do |(id, name), count|
    f.puts "ID: #{id} | Name: #{name} | Count: #{count}"
  end
  
  f.puts "\n--- CHECKING FOR NAME COLLISIONS (DUPLICATES) ---"
  counts = Profissional.group(:nome).count.select{|k,v| v > 1}
  f.puts "Duplicate Names: #{counts.inspect}"
end
