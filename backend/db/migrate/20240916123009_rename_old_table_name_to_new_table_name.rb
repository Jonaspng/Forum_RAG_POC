class RenameOldTableNameToNewTableName < ActiveRecord::Migration[7.2]
  def change
    rename_table :course_material, :course_materials
  end
end
