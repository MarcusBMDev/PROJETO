class AddDataEncaixeToAgendamentos < ActiveRecord::Migration[8.1]
  def change
    add_column :agendamentos, :data_encaixe, :date
  end
end
