class WidgetTestsController < ActionController::Base
  PAGES = {
    'home' => {
      heading: 'Welcome to Acme',
      lede: 'A sample website for testing live chat campaigns.',
      wait: 3,
      campaign: '[Test] Welcome on Home'
    },
    'pricing' => {
      heading: 'Simple pricing',
      lede: 'Stay on this page — a pricing campaign should appear after a few seconds.',
      wait: 3,
      campaign: '[Test] Pricing help'
    },
    'about' => {
      heading: 'About Acme',
      lede: 'This page waits a little longer so you can confirm URL-specific triggers.',
      wait: 5,
      campaign: '[Test] About us'
    }
  }.freeze

  helper_method :page_href

  before_action :ensure_web_widget
  before_action :ensure_widget_position
  before_action :ensure_widget_type
  before_action :ensure_widget_style
  before_action :ensure_dark_mode
  before_action :ensure_page

  def index
    render
  end

  private

  def ensure_page
    if params[:page].blank?
      redirect_to page_href('home')
      return
    end

    unless PAGES.key?(params[:page])
      head :not_found
      return
    end

    @page_key = params[:page]
    @page = PAGES[@page_key]
  end

  def page_href(page)
    widget_test_page_path(page, request.query_parameters.except('page'))
  end

  def ensure_widget_style
    @widget_style = params[:widget_style] || 'standard'
  end

  def ensure_dark_mode
    @dark_mode = params[:dark_mode] || 'light'
  end

  def ensure_widget_position
    @widget_position = params[:position] || 'right'
  end

  def ensure_widget_type
    @widget_type = params[:type] || 'expanded_bubble'
  end

  def inbox_id
    @inbox_id ||= params[:inbox_id].presence || Channel::WebWidget.first.inbox.id
  end

  def ensure_web_widget
    @inbox = Inbox.find(inbox_id)
    @web_widget = @inbox.channel
  end
end
