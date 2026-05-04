class AddEncaixeToAgendamentosAndExpandTransferencias < ActiveRecord::Migration[8.1]
  def change
    # 1. Agendamentos: Adiciona flag de encaixe e remove o índice de unicidade estrito
    add_column :agendamentos, :encaixe, :boolean, default: false
    
    # Remove o índice de unicidade que impede múltiplos agendamentos no mesmo horário
    remove_index :agendamentos, name: "idx_agendamentos_unicidade" if index_exists?(:agendamentos, name: "idx_agendamentos_unicidade")
    
    # Adiciona um índice regular para performance, mas sem o "unique: true"
    add_index :agendamentos, [:profissional_id, :dia_semana, :horario], name: "idx_agendamentos_busca"

    # 2. Transferencias: Expandir para se tornar solicitações de agenda (Remoção, Redução)
    add_column :transferencias, :tipo, :integer, default: 0 # 0: transferencia, 1: remocao, 2: reducao
    add_column :transferencias, :solicitante, :string
    add_column :transferencias, :agendamento_ids, :text # Para armazenar IDs no caso de remoção/redução múltipla
    
    # Permite que o campo de destino seja nulo (necessário para remoção/redução)
    change_column_null :transferencias, :para_profissional_id, true
    change_column_null :transferencias, :de_profissional_id, true
  end
end
