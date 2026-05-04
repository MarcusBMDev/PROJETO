class AddAtivoToConvenios < ActiveRecord::Migration[8.1]
  def change
    add_column :convenios, :ativo, :boolean
  end
end
