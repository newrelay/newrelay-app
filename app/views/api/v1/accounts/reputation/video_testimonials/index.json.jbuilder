json.array! @video_testimonials do |testimonial|
  json.id testimonial.id
  json.title testimonial.title
  json.customer_name testimonial.customer_name
  json.company testimonial.company
  json.email testimonial.email
  json.status testimonial.status
  json.rating testimonial.rating
  json.platform testimonial.platform
  json.duration_seconds testimonial.duration_seconds
  json.views testimonial.views
  json.created_at testimonial.created_at.to_i
  json.contact do
    if testimonial.contact
      json.id testimonial.contact.id
      json.name testimonial.contact.name
    else
      json.null!
    end
  end
  json.video_url testimonial.video.attached? ? url_for(testimonial.video) : nil
  json.thumbnail_url testimonial.thumbnail.attached? ? url_for(testimonial.thumbnail) : nil
  json.notes testimonial.notes
  json.ai_insights testimonial.ai_insights
  json.token testimonial.token
  json.share_url reputation_testimonial_url(token: testimonial.token)
end
