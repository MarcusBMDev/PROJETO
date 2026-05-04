class AddAtivoToProfissionais < ActiveRecord::Migration[8.1]
  def change
    add_column :profissionais, :ativo, :boolean, default: true
  end
end
