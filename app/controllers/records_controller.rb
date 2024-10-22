class RecordsController < ApplicationController
  # Disable CSRF protection for this controller because we are not using forms
  skip_before_action :verify_authenticity_token, only: [:create, :destroy_by_attributes]
  before_action :initialize_google_sheets_service
  before_action :set_google_sheet_details

  def index
    result = fetch_records_from_sheet
    records = result[:records]
    Rails.logger.info("Fetched records: #{records.inspect}")
    render json: records
  end

  def create
    # Extract and validate parameters from JSON input
    new_row_params = record_params
    Rails.logger.info("Create params: #{new_row_params.inspect}")

    # Create a new row with the extracted values
    @new_row = [
      new_row_params[:date],
      new_row_params[:description],
      new_row_params[:category],
      new_row_params[:sub_category],
      new_row_params[:amount],
      new_row_params[:remark]
    ]
    
    # Append the new row to the sheet
    @google_sheets_service.write_sheet(@spreadsheet_key, @worksheet_title, [@new_row])
    Rails.logger.info("New row added: #{@new_row.inspect}")

    render json: { message: 'Row added successfully' }, status: :created  
  end

  def destroy_by_attributes
    # Extract and validate parameters from JSON input
    delete_params = record_params
    Rails.logger.info("Delete params: #{delete_params.inspect}")

    # Check for row that matches the column values
    result = fetch_records_from_sheet
    keys = result[:keys]
    records = result[:records]
    Rails.logger.info("Fetched records: #{records.inspect}")

    # Find the row number of the record to be deleted
    row_number = records.find_index do |record|
      record['Date'] == delete_params[:date] &&
        record['Description'] == delete_params[:description] &&
        record['Category'] == delete_params[:category] &&
        record['Sub Category'] == delete_params[:sub_category] &&
        record['Amount'].to_s == delete_params[:amount].to_s &&  # Convert amount to string for comparison
        record['Remark'] == delete_params[:remark]
    end

    if row_number.nil?
      render json: { error: 'Record not found' }, status: :not_found
    else
      # Delete the row from the sheet
      @google_sheets_service.delete_row(@spreadsheet_key, @worksheet_title, row_number + 2)
      Rails.logger.info("Row deleted: #{records[row_number].inspect}")
      render json: { message: 'Row deleted successfully' }, status: :ok
    end
  end

  private

  def initialize_google_sheets_service
    @google_sheets_service = GoogleSheetsService.new
  end

  def set_google_sheet_details
    @spreadsheet_key = ENV['GOOGLE_SHEET_KEY']
    @worksheet_title = ENV['GOOGLE_SHEET_TITLE']
  end

  def fetch_records_from_sheet
    # Read data from the Google Sheet
    rows = @google_sheets_service.read_sheet(@spreadsheet_key, @worksheet_title)

    # Extract keys from the first row
    keys = rows[0]

    # Initialize records array
    records = []

    # Iterate over remaining rows and create hashes
    rows[1..].each do |row|
      record = {}
      keys.each_with_index do |key, i|
        record[key] = row[i] || nil  # Assign nil if the column is missing
      end
      records << record
    end

    {
      keys: keys,
      records: records
    }
  end
    
  def record_params
    params.require(:record).permit(:date, :description, :category, :sub_category, :amount, :remark)
  end
end
