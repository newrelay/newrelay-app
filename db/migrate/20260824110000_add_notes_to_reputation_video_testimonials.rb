class AddNotesToReputationVideoTestimonials < ActiveRecord::Migration[7.1]
  def change
    add_column :reputation_video_testimonials, :notes, :jsonb, default: [], null: false
  end
end
