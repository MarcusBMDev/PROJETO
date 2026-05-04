class AddFieldsToPacientes < ActiveRecord::Migration[8.1]
  def change
    add_column :pacientes, :age, :integer
    add_column :pacientes, :convenio_id, :integer
    add_column :pacientes, :weekly_frequency, :integer
    add_column :pacientes, :planned_specialties, :text
    add_column :pacientes, :status, :string
    add_column :pacientes, :deleted_at, :datetime
  end
end
