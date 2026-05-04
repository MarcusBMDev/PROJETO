class CreateAgendamentos < ActiveRecord::Migration[8.1]
  def change
    create_table :agendamentos do |t|
      t.references :profissional, null: false, foreign_key: true
      t.references :paciente, null: false, foreign_key: true
      t.references :convenio, null: false, foreign_key: true
      t.string :dia_semana
      t.string :horario
      t.text :observacoes

      t.timestamps
    end
  end
end
