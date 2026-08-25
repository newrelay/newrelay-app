class AddAiInsightsToReputationVideoTestimonials < ActiveRecord::Migration[7.1]
  def change
    # jsonb blob: { transcript, summary, topics[], sentiment, marketing_score,
    # quotable, suggested_reply, processed_at, error }. Blank until analyzed.
    add_column :reputation_video_testimonials, :ai_insights, :jsonb, default: {}, null: false
  end
end
