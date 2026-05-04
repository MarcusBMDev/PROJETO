# app/models/concerns/age_calculable.rb
module AgeCalculable
  extend ActiveSupport::Concern

  included do
    before_save :calculate_age_from_birth_date
  end

  # Calcula a idade baseada na data de nascimento ou mantém o valor fixo do campo age
  def idade
    return age if birth_date.blank?
    
    hoje = Time.zone.today
    calculo = hoje.year - birth_date.year
    calculo -= 1 if hoje < birth_date + calculo.years
    [calculo, 0].max
  end

  private

  def calculate_age_from_birth_date
    self.age = idade if birth_date.present?
  end
end
