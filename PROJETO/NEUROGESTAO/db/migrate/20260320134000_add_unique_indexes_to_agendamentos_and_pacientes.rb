class AddUniqueIndexesToAgendamentosAndPacientes < ActiveRecord::Migration[8.1]
  def change
    # Adiciona índice único para evitar duplicidade de agendamento (Profissional/Dia/Horário)
    unless index_exists?(:agendamentos, [:profissional_id, :dia_semana, :horario], name: 'idx_agendamentos_unicidade')
      add_index :agendamentos, [:profissional_id, :dia_semana, :horario], unique: true, name: 'idx_agendamentos_unicidade'
    end

    # Adiciona índice único para o nome do paciente
    unless index_exists?(:pacientes, :nome)
      add_index :pacientes, :nome, unique: true
    end
  end
end
