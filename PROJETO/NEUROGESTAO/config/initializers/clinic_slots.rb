# config/initializers/clinic_slots.rb

# Centralização dos horários de atendimento da clínica para facilitar manutenção futura.
module ClinicSlots
  # Horários específicos para SEGUNDA-FEIRA
  MONDAY = ["08:00", "08:40", "09:20", "10:00", "10:40", "11:20", "14:00", "14:40", "15:20", "16:00", "16:40", "17:20"].freeze

  # Horários padrão para TERÇA a SEXTA
  STANDARD = ["08:00", "08:40", "09:20", "10:00", "10:40", "11:20", "14:00", "14:40", "15:20", "16:00", "16:40", "17:20"].freeze

  # Mapeamento completo
  ALL = {
    "SEGUNDA-FEIRA" => MONDAY,
    "TERÇA-FEIRA"   => STANDARD,
    "QUARTA-FEIRA"  => STANDARD,
    "QUINTA-FEIRA"  => STANDARD,
    "SEXTA-FEIRA"   => STANDARD
  }.freeze
end
