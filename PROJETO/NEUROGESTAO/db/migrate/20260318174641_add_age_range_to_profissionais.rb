class AddAgeRangeToProfissionais < ActiveRecord::Migration[8.1]
  def change
    add_column :profissionais, :min_age, :integer
    add_column :profissionais, :max_age, :integer
  end
end
