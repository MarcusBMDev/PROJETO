class AddBlockingToAgendamentos < ActiveRecord::Migration[8.1]
  def change
    add_column :agendamentos, :motivo_bloqueio, :text
    add_column :agendamentos, :bloqueado_por, :string
  end
end
