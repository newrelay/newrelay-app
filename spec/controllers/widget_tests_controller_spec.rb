require 'rails_helper'

describe '/widget_tests', type: :request do
  before do
    create(:channel_widget)
  end

  describe 'GET /widget_tests' do
    it 'redirects to the home page' do
      get widget_tests_url
      expect(response).to redirect_to(widget_test_page_path('home'))
    end
  end

  describe 'GET /widget_tests/home' do
    it 'renders the page correctly' do
      get widget_test_page_url('home')
      expect(response).to be_successful
      expect(response.body).to include('Welcome to Acme')
    end
  end
end
