class CreateTargetCasinos < ActiveRecord::Migration
  def up
    create_table :target_casinos do |t|
      t.integer :change_log_id
      t.integer :target_casino_id
    end

    execute "ALTER TABLE target_casinos ADD CONSTRAINT fk_TargetCasinos_ChangeLogId FOREIGN KEY (change_log_id) REFERENCES change_logs (id)"
  end

  def down
    drop_table(:target_casinos)
  end
end
