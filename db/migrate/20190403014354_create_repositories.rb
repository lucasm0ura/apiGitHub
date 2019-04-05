class CreateRepositories < ActiveRecord::Migration[5.2]
  def change
    create_table :repositories do |t|
      t.string :name
      t.string :full_name
      t.string :url
      t.text :description
      t.string :language
      t.integer :stargazers_count
      t.integer :forks
      t.integer :open_issues
      t.integer :watchers
      t.string :owner_login
      t.string :owner_avatar_url

      t.timestamps
    end
  end
end
