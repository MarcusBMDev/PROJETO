class MergeDuplicateConvenios < ActiveRecord::Migration[8.1]
  def up
    # Agrupa convênios por nome (ignorando maiúsculas/minúsculas e espaços extras)
    grupos = Convenio.all.group_by { |c| c.nome.to_s.strip.upcase }

    grupos.each do |nome_normalizado, convenios|
      # Se há 1 ou nenhum convênio com este nome, não há duplicatas
      next if convenios.size <= 1

      # Ordena por ID: o menor ID será o principal (primeiro criado)
      convenios_ordenados = convenios.sort_by(&:id)
      convenio_principal = convenios_ordenados.first
      convenios_duplicados = convenios_ordenados[1..]

      ids_duplicados = convenios_duplicados.map(&:id)

      # 1. Redireciona todos os pacientes vinculados aos IDs duplicados para o ID principal
      Paciente.where(convenio_id: ids_duplicados).update_all(convenio_id: convenio_principal.id)

      # 2. Redireciona todos os agendamentos vinculados aos IDs duplicados para o ID principal
      Agendamento.where(convenio_id: ids_duplicados).update_all(convenio_id: convenio_principal.id)

      # 3. Agora que os vínculos foram preservados e movidos, apaga as duplicadas de forma segura
      Convenio.where(id: ids_duplicados).destroy_all

      puts "[FUSÃO] Convênios duplicados de '#{nome_normalizado}' foram mesclados com sucesso sob o ID ##{convenio_principal.id}."
    end
  end

  def down
    # Migração de dados destrutiva de duplicatas é irreversível
  end
end
