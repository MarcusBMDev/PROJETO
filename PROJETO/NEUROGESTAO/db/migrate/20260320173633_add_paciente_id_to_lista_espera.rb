class AddPacienteIdToListaEspera < ActiveRecord::Migration[8.1]
  def change
    add_column :lista_espera, :paciente_id, :bigint
    add_index :lista_espera, :paciente_id
  end
end
