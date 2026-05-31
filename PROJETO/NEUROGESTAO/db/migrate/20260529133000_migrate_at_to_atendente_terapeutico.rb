class MigrateAtToAtendenteTerapeutico < ActiveRecord::Migration[8.1]
  def up
    # 1. Atualiza a especialidade nos profissionais ativos/inativos
    Profissional.find_each do |p|
      next if p.especialidade.blank?
      
      # Divide as especialidades, remove espaços extras
      esps = p.especialidade.split(',').map(&:strip)
      
      # Verifica se contém a especialidade "AT" (case-insensitive)
      if esps.any? { |e| e.upcase == 'AT' }
        # Substitui "AT" por "ATENDENTE TERAPEUTICO"
        esps.map! { |e| e.upcase == 'AT' ? 'ATENDENTE TERAPEUTICO' : e }
        
        # Remove duplicados caso o profissional já tivesse ambas registradas
        esps = esps.uniq
        
        # Salva o valor atualizado no banco
        p.update_columns(especialidade: esps.join(', '))
      end
    end

    # 2. Atualiza a tabela global de especialidades (especialidades)
    # Remove a antiga "AT"
    Especialidade.where("UPPER(nome) = 'AT'").destroy_all
    
    # Garante que "ATENDENTE TERAPEUTICO" existe na tabela
    Especialidade.find_or_create_by!(nome: 'ATENDENTE TERAPEUTICO')
  end

  def down
    # Sem reversão obrigatória para este ajuste de dados
  end
end
