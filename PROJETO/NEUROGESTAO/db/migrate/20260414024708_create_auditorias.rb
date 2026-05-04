class CreateAuditorias < ActiveRecord::Migration[8.1]
  def change
    create_table :auditorias do |t|
      t.integer :user_id
      t.string :user_name
      t.string :setor
      t.string :acao
      t.string :entidade_tipo
      t.integer :entidade_id
      t.text :detalhes
      t.string :ip_address

      t.timestamps
    end

    add_index :auditorias, :user_id
    add_index :auditorias, :acao
    add_index :auditorias, [:entidade_tipo, :entidade_id]
    add_index :auditorias, :created_at
  end
end
