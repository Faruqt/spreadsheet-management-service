require 'google_drive'
require 'json'
require 'stringio'

class GoogleSheetsService
  # Initializes a new instance of the GoogleSheetsService.
  #
  # @raise [RuntimeError] if the GOOGLE_SERVICE_ACCOUNT_CREDENTIALS environment variable is not set.
  def initialize
    credentials_json = ENV['GOOGLE_SERVICE_ACCOUNT_CREDENTIALS']
    raise "GOOGLE_SERVICE_ACCOUNT_CREDENTIALS environment variable not set" unless credentials_json

    credentials = JSON.parse(credentials_json)
    @session = GoogleDrive::Session.from_service_account_key(StringIO.new(credentials_json))
    @spreadsheet_key = ENV['GOOGLE_SHEET_KEY']
    @worksheet_title = ENV['GOOGLE_SHEET_TITLE']
  end

  # Reads all rows from a specified worksheet in the spreadsheet.
  #
  # @param spreadsheet_key [String] The key of the spreadsheet.
  # @param worksheet_title [String] The title of the worksheet.
  # @return [Array<Array<String>>] The rows from the worksheet.
  # @raise [GoogleDrive::Error] if the worksheet cannot be found or read.
  def read_sheet(spreadsheet_key, worksheet_title)
    worksheet = find_worksheet(spreadsheet_key, worksheet_title)
    worksheet.rows
  end

  # Writes multiple rows to a specified worksheet in the spreadsheet.
  #
  # @param spreadsheet_key [String] The key of the spreadsheet.
  # @param worksheet_title [String] The title of the worksheet.
  # @param rows [Array<Array<String>>] The rows to be written to the worksheet.
  # @raise [GoogleDrive::Error] if the rows cannot be written.
  def write_sheet(spreadsheet_key, worksheet_title, rows)
    worksheet = find_worksheet(spreadsheet_key, worksheet_title)
    worksheet.insert_rows(worksheet.num_rows + 1, rows)
    worksheet.save
  end

  # Updates a specified row in the worksheet with new values.
  #
  # @param spreadsheet_key [String] The key of the spreadsheet.
  # @param worksheet_title [String] The title of the worksheet.
  # @param row_number [Integer] The row number to be updated (1-based index).
  # @param row [Array<String>] The new values for the row.
  # @raise [GoogleDrive::Error] if the row cannot be updated.
  def update_sheet(spreadsheet_key, worksheet_title, row_number, row)
    worksheet = find_worksheet(spreadsheet_key, worksheet_title)
    worksheet[row_number, 1] = row
    worksheet.save
  end

  # Deletes a specified row from the worksheet.
  #
  # @param spreadsheet_key [String] The key of the spreadsheet.
  # @param worksheet_title [String] The title of the worksheet.
  # @param row_number [Integer] The row number to be deleted (1-based index).
  # @raise [GoogleDrive::Error] if the row cannot be deleted.
  def delete_row(spreadsheet_key, worksheet_title, row_number)
    worksheet = find_worksheet(spreadsheet_key, worksheet_title)
    worksheet.delete_rows(row_number, 1) 
    worksheet.save
  end

  # Fetch records from the Google Sheet
  # @return [Hash] A hash containing the keys and records
  def fetch_records_from_sheet(page=nil, per_page=nil)
    begin
      # Read data from the Google Sheet
      rows = read_sheet(@spreadsheet_key, @worksheet_title)

      # Extract keys from the first row
      keys = rows[0]

      # Initialize records array
      records = []

      if page && per_page
        # Calculate pagination offsets
        start_index = (page - 1) * per_page + 1
        end_index = start_index + per_page - 1
        records_rows = rows[start_index..end_index].reverse
      else
        records_rows = rows[1..]
      end

      # Iterate over remaining rows and create hashes
      records_rows.each do |row|
        record = {}
        keys.each_with_index do |key, i|
          record[key] = row[i] || nil  # Assign nil if the column is missing
        end
        records << record
      end

      Rails.logger.info("Records fetched: #{records.inspect}")
      {
        keys: keys,
        records: records,
        total_records: rows.length - 1
      }
    rescue StandardError => e
      Rails.logger.error("Failed to fetch records: #{e.message}")
      raise e
    end
  end

  # Create a new record in the sheet
  # @param new_row_params [Hash] The parameters to be added
  # new_row_params should be a hash with the following keys
  # :date, :description, :category, :sub_category, :amount, :remark
  # @return [Boolean] True if the record is added, False otherwise
  def create_new_record(new_row_params)
    Rails.logger.info("New row params: #{new_row_params.inspect}")

    unless validate_record_params(new_row_params)
      raise ArgumentError, "Invalid parameters: #{new_row_params.inspect}"
    end

    # Create a new row with the extracted values
    @new_row = [
      new_row_params[:date],
      new_row_params[:description],
      new_row_params[:category],
      new_row_params[:sub_category],
      new_row_params[:amount],
      new_row_params[:remark]
    ]

    begin
      # Append the new row to the sheet
      write_sheet(@spreadsheet_key, @worksheet_title, [@new_row])
      Rails.logger.info("New row added: #{@new_row.inspect}")
      true
    rescue StandardError => e
      Rails.logger.error("Failed to add new row: #{e.message}")
      raise e
    end
  end

  # Retrieves the row number of the record to be deleted based on provided parameters.
  #
  # @param delete_params [Hash] The parameters used to find the record to delete.
  #   Should include :date, :description, :category, :sub_category, :amount, and :remark.
  # @return [Integer] The row number of the record to be deleted, or nil if not found.
  # @raise [StandardError] if the records cannot be fetched.
  def get_record_to_be_deleted(delete_params)
    Rails.logger.info("Delete params: #{delete_params.inspect}")

    # Check for row that matches the column values
    result = fetch_records_from_sheet
    keys = result[:keys]
    records = result[:records]

    # Find the row number of the record to be deleted from the bottom up
    row_number = records.rindex do |record|
      record['Date'] == delete_params[:date] &&
        record['Description'] == delete_params[:description] &&
        record['Category'] == delete_params[:category] &&
        record['Sub Category'] == delete_params[:sub_category] &&
        record['Amount'].to_s == delete_params[:amount].to_s &&  # Convert amount to string for comparison
        record['Remark'] == delete_params[:remark]
    end

    row_number
  end

  # Deletes a record from the sheet based on the provided parameters.
  #
  # @param delete_params [Hash] The parameters used to find and delete the record.
  #   Should include :date, :description, :category, :sub_category, :amount, and :remark.
  # @return [Boolean] True if the record is deleted, False otherwise.
  # @raise [ArgumentError] if the parameters are invalid.
  # @raise [StandardError] if the record cannot be deleted.
  def delete_records_from_sheet(delete_params)
    unless validate_record_params(delete_params)
      raise ArgumentError, "Invalid parameters: #{delete_params.inspect}"
    end

    begin
      row_number = get_record_to_be_deleted(delete_params)

      if row_number
        # Delete the row from the sheet
        delete_row(@spreadsheet_key, @worksheet_title, row_number + 2)
        status = true
      else
        status = false
      end
    rescue StandardError => e
      Rails.logger.error("Failed to delete row: #{e.message}")
      # Re-raise the exception to be handled by the caller
      raise e
    end
  end

  private

  # Finds a worksheet by its title in the specified spreadsheet.
  # 
  # @param spreadsheet_key [String] The key of the spreadsheet.
  # @param worksheet_title [String] The title of the worksheet.
  # @return [GoogleDrive::Worksheet] The found worksheet.
  # @raise [GoogleDrive::Error] if the worksheet cannot be found.
  def find_worksheet(spreadsheet_key, worksheet_title)
    spreadsheet = @session.spreadsheet_by_key(spreadsheet_key)
    spreadsheet.worksheet_by_title(worksheet_title)
  end

  # Validate the record parameters
  # 
  # @param record_params [Hash] The parameters to be validated
  # record_params should be a hash with the following keys:
  # :date, :description, :category, :sub_category, :amount, :remark
  # @return [Boolean] True if the parameters are valid, False otherwise
  def validate_record_params(record_params)
    required_keys = [:date, :description, :category, :sub_category, :amount, :remark]
    missing_keys = required_keys - record_params.keys

    missing_keys.empty?
  end

end