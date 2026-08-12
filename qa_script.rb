account = Account.first
contact = account.contacts.first
template = account.reputation_templates.where(template_type: [nil, 'standard']).first
video_template = account.reputation_templates.where(template_type: 'video').first

puts "=== QA: Send Standard Request ==="
if template && contact
  begin
    Reputation::ReviewRequestSendService.new(
      account: account,
      template_id: template.id,
      contact_id: contact.id
    ).send!
    puts "✅ Standard Request Sent Successfully"
  rescue => e
    puts "❌ Standard Request Failed: #{e.message}"
  end
else
  puts "⚠️ Missing data for standard request test (Contact or Template)"
end

puts "\n=== QA: Send Video Request ==="
if video_template
  begin
    # simulate the payload sent to VideoTestimonialsController#dispatch_request
    request = account.reputation_review_requests.create!(
      reputation_template: video_template,
      channel: video_template.channel,
      status: 'sent',
      contact: contact
    )
    
    ReputationRequestMailer.send_request(
      request.id,
      "test_email@example.com",
      "Test Subject",
      "Test body"
    ).deliver_now
    puts "✅ Video Request Dispatched Successfully"
  rescue => e
    puts "❌ Video Request Failed: #{e.message}"
    puts e.backtrace.first(5)
  end
else
  puts "⚠️ Missing video template for test"
end

puts "\n=== QA: Upload Video ==="
begin
  # Simulate upload via ActiveStorage
  video_file = ActionDispatch::Http::UploadedFile.new({
    filename: 'test_video.mp4',
    type: 'video/mp4',
    tempfile: Tempfile.new('test_video.mp4')
  })
  
  testimonial = account.reputation_video_testimonials.create!(
    title: "QA Test Video",
    email: "qa@example.com"
  )
  testimonial.video.attach(video_file)
  
  if testimonial.persisted? && testimonial.video.attached?
    puts "✅ Video Testimonial Uploaded Successfully"
  else
    puts "❌ Video Upload Failed Validation"
  end
rescue => e
  puts "❌ Video Upload Failed: #{e.message}"
end
