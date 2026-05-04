class AddNewTimeFieldsToTransferencias < ActiveRecord::Migration[8.1]
  def change
    add_column :transferencias, :novo_dia_semana, :string
    add_column :transferencias, :novo_horario, :string
    add_column :transferencias, :agendamento_origem_id, :bigint
  end
end
