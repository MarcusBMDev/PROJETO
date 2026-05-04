class CreateEspecialidades < ActiveRecord::Migration[8.1]
  def change
    create_table :especialidades do |t|
      t.string :nome, null: false # Nome da especialidade

      t.timestamps
    end
    
    # Adicione esta linha manualmente se ela não estiver lá:
    add_index :especialidades, :nome, unique: true
  end
end