class AddCorToAgendamentos < ActiveRecord::Migration[8.1]
  def change
    add_column :agendamentos, :cor, :string
  end
end
