class UpdateWaitlistAndAppointments < ActiveRecord::Migration[8.1]
  def change
    # Melhorias na Lista de Espera
    add_column :lista_espera, :birth_date, :date
    add_column :lista_espera, :age, :integer
    add_column :lista_espera, :planned_specialties, :text
    add_column :lista_espera, :status, :string, default: 'aguardando'

    # Melhorias nos Agendamentos para suportar Bloqueio/Aprovação
    add_column :agendamentos, :status, :string, default: 'confirmado'
    add_column :agendamentos, :lista_espera_id, :bigint
    
    add_index :agendamentos, :lista_espera_id
    add_index :agendamentos, :status
  end
end
