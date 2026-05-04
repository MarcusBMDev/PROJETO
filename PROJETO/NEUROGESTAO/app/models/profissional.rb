# app/models/profissional.rb
class Profissional < ApplicationRecord
  self.table_name = 'profissionais'

  has_many :agendamentos, dependent: :restrict_with_error
  has_one_attached :curriculo
  has_many :transferencias_de,
           class_name: 'Transferencia',
           foreign_key: 'de_profissional_id',
           dependent: :restrict_with_error
  has_many :transferencias_para,
           class_name: 'Transferencia',
           foreign_key: 'para_profissional_id',
           dependent: :restrict_with_error

  validates :nome, presence: true
  validates :min_age,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
  validates :max_age,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
  validate :max_age_deve_ser_maior_que_min_age

  scope :ativos,   -> { where(ativo: true) }
  scope :inativos, -> { where(ativo: false) }

  def inativar!
    update!(ativo: false)
  end

  private

  def max_age_deve_ser_maior_que_min_age
    return if min_age.blank? || max_age.blank?
    if max_age < min_age
      errors.add(:max_age, "não pode ser menor que a idade mínima (#{min_age})")
    end
  end
end
