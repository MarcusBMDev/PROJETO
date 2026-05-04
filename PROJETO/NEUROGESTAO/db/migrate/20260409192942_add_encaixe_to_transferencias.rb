class AddEncaixeToTransferencias < ActiveRecord::Migration[8.1]
  def change
    add_column :transferencias, :encaixe, :boolean
  end
end
