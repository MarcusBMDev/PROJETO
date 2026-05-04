class CreateTransferencias < ActiveRecord::Migration[8.1]
  def change
    create_table :transferencias do |t|
      t.references :paciente, null: false, foreign_key: true
      t.references :de_profissional, null: false, foreign_key: { to_table: :profissionais }
      t.references :para_profissional, null: false, foreign_key: { to_table: :profissionais }
      t.string :status, default: 'pendente'
      t.text :motivo

      t.timestamps
    end
  end
end
