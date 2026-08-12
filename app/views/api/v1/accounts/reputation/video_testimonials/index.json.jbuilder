json.array! @video_testimonials do |testimonial|
  json.id testimonial.id
  json.title testimonial.title
  json.email testimonial.email
  json.status testimonial.status
  json.created_at testimonial.created_at.to_i
  if testimonial.video.attached?
    json.video_url url_for(testimonial.video)
  else
    json.video_url nil
  end
end
