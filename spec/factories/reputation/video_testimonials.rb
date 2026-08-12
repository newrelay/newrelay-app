FactoryBot.define do
  factory :reputation_video_testimonial, class: 'Reputation::VideoTestimonial' do
    account { nil }
    title { "MyString" }
    email { "MyString" }
    status { "MyString" }
    token { "MyString" }
  end
end
