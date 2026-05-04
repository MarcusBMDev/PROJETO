class AddBloqueadoPorIdToAgendamentos < ActiveRecord::Migration[8.1]
  def change
    add_column :agendamentos, :bloqueado_por_id, :integer
  end
end
