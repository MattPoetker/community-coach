# frozen_string_literal: true

# Postgres full-text search, generated rather than maintained by callbacks — a trigger-free
# generated column cannot drift from the text it indexes.
class AddSearchVectors < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE posts ADD COLUMN search_vector tsvector
        GENERATED ALWAYS AS (
          setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(body_text, '')), 'B')
        ) STORED;

      ALTER TABLE comments ADD COLUMN search_vector tsvector
        GENERATED ALWAYS AS (to_tsvector('english', coalesce(body_text, ''))) STORED;

      ALTER TABLE lessons ADD COLUMN search_vector tsvector
        GENERATED ALWAYS AS (setweight(to_tsvector('english', coalesce(title, '')), 'A')) STORED;
    SQL

    add_index :posts, :search_vector, using: :gin
    add_index :comments, :search_vector, using: :gin
    add_index :lessons, :search_vector, using: :gin
  end

  def down
    remove_column :posts, :search_vector
    remove_column :comments, :search_vector
    remove_column :lessons, :search_vector
  end
end
