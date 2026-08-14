# ponytail: CSV helpers duplicated from DataImportJob to keep contact import untouched;
# extract a shared concern when the contact job's "clean this up" TODO is addressed.
class CompanyDataImportJob < ApplicationJob
  queue_as :low
  retry_on ActiveStorage::FileNotFoundError, wait: 1.minute, attempts: 3

  def perform(data_import)
    @data_import = data_import
    @company_manager = DataImport::CompanyManager.new(@data_import.account)
    process_import_file
  rescue CSV::MalformedCSVError
    @data_import.update!(status: :failed)
  end

  private

  def process_import_file
    @data_import.update!(status: :processing)
    companies, rejected = parse_csv_and_build_companies

    Company.import(companies, on_duplicate_key_ignore: true, track_validation_failures: true, validate: true, batch_size: 1000)
    @data_import.update!(status: :completed, processed_records: companies.length, total_records: companies.length + rejected.length)
    save_failed_records_csv(rejected)
  end

  def parse_csv_and_build_companies
    companies = []
    rejected = []

    with_import_file do |file|
      csv_reader(file).each do |row|
        company = @company_manager.build_company(row.to_h.with_indifferent_access)
        if company.valid?
          companies << company
        else
          row['errors'] = company.errors.full_messages.join(', ')
          rejected << row
        end
      end
    end

    [companies, rejected]
  end

  def save_failed_records_csv(rejected_companies)
    return if rejected_companies.blank?

    headers = csv_headers << 'errors'
    csv_data = CSV.generate do |csv|
      csv << headers
      rejected_companies.each { |record| csv << record }
    end

    @data_import.failed_records.attach(io: StringIO.new(csv_data), filename: "#{Time.zone.today.strftime('%Y%m%d')}_companies.csv",
                                       content_type: 'text/csv')
  end

  def csv_headers
    header_row = nil
    with_import_file { |file| header_row = csv_reader(file).first }
    header_row&.headers || []
  end

  def csv_reader(file)
    file.rewind
    raw_data = file.read
    utf8_data = raw_data.force_encoding('UTF-8')
    clean_data = utf8_data.valid_encoding? ? utf8_data : utf8_data.encode('UTF-16le', invalid: :replace, replace: '').encode('UTF-8')
    clean_data = clean_data.delete_prefix("\xEF\xBB\xBF")

    CSV.new(StringIO.new(clean_data), headers: true)
  end

  def with_import_file
    temp_dir = Rails.root.join('tmp/imports')
    FileUtils.mkdir_p(temp_dir)

    @data_import.import_file.open(tmpdir: temp_dir) do |file|
      file.binmode
      yield file
    end
  end
end
