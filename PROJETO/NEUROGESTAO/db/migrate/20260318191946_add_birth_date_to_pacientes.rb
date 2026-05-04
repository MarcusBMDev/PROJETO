class AddBirthDateToPacientes < ActiveRecord::Migration[8.0]
  def change
    add_column :pacientes, :birth_date, :date
  end
end
