class CreateListaEspera < ActiveRecord::Migration[8.1]
  def change
    create_table :lista_espera do |t|
      t.string :nome
      t.string :telefone
      t.string :especialidade
      t.text :observacao

      t.timestamps
    end
  end
end
