class AddDetailFieldsToConvenios < ActiveRecord::Migration[8.1]
  def change
    add_column :convenios, :exigencias, :text
    add_column :convenios, :especialidades_atendidas, :text
  end
end
