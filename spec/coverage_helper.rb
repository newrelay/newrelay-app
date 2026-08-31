require 'simplecov'
require 'simplecov_json_formatter'

# JSON for Qlty/CI, HTML for local inspection.
SimpleCov.formatters = [
  SimpleCov::Formatter::JSONFormatter,
  SimpleCov::Formatter::HTMLFormatter
]
SimpleCov.start 'rails' do
  SimpleCov.coverage_dir 'coverage'
  # Unset = report only. Set COVERAGE_MINIMUM (e.g. 70) to ratchet the floor.
  # Target for new billing/webhook/auth code is 95% (docs/adr/0003).
  if (min = ENV['COVERAGE_MINIMUM']).present?
    minimum_coverage min.to_f
  end
end
