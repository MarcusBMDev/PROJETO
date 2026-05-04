# limpar_banco.rb
puts "🗑️  A iniciar a limpeza total do banco de dados..."

ActiveRecord::Base.connection.disable_referential_integrity do
  Agendamento.delete_all
  Paciente.delete_all
  Profissional.delete_all
  Convenio.delete_all
  ListaEspera.delete_all
  
  ActiveRecord::Base.connection.execute("ALTER TABLE agendamentos AUTO_INCREMENT = 1")
  ActiveRecord::Base.connection.execute("ALTER TABLE pacientes AUTO_INCREMENT = 1")
  ActiveRecord::Base.connection.execute("ALTER TABLE profissionais AUTO_INCREMENT = 1")
  ActiveRecord::Base.connection.execute("ALTER TABLE convenios AUTO_INCREMENT = 1")
  ActiveRecord::Base.connection.execute("ALTER TABLE lista_esperas AUTO_INCREMENT = 1")
end

puts "✅  Banco de dados limpo e IDs reiniciados!"