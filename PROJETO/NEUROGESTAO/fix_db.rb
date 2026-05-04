# fix_db.rb
connection = ActiveRecord::Base.connection
tables = {
  active_storage_blobs: -> {
    connection.create_table :active_storage_blobs do |t|
      t.string :key, null: false; t.string :filename, null: false; t.string :content_type; t.text :metadata
      t.string :service_name, null: false; t.bigint :byte_size, null: false; t.string :checksum; t.datetime :created_at, null: false
      t.index [:key], unique: true
    end
  },
  active_storage_attachments: -> {
    connection.create_table :active_storage_attachments do |t|
      t.string :name, null: false; t.references :record, null: false, polymorphic: true, index: false
      t.references :blob, null: false; t.datetime :created_at, null: false
      t.index [:record_type, :record_id, :name, :blob_id], name: :index_active_storage_attachments_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  },
  active_storage_variant_records: -> {
    connection.create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false; t.string :variation_digest, null: false
      t.index [:blob_id, :variation_digest], name: :index_active_storage_variant_records_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  }
}
tables.each { |name, proc| proc.call unless connection.table_exists?(name) }
puts "✅ Tabelas corrigidas!"
