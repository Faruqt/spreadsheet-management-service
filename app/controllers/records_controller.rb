#
# RecordsController handles CRUD operations for records stored in a Google Sheets document.
# 
# Actions:
# - index: Fetches and returns paginated records from the Google Sheets document.
# - create: Adds a new record to the Google Sheets document.
# - destroy_by_attributes: Deletes records from the Google Sheets document based on provided attributes.
#
# Before Actions:
# - skip_before_action :verify_authenticity_token: Disables CSRF protection for create and destroy_by_attributes actions.
#
# Rescue From:
# - StandardError: Handles generic errors and returns a 500 internal server error response.
# - ArgumentError: Handles argument-related errors and returns a 422 unprocessable entity response.
#
# Private Methods:
# - google_sheets_service: Initializes and returns an instance of GoogleSheetsService.
# - handle_standard_error: Logs and handles generic errors.
# - handle_argument_error: Logs and handles argument-related errors.
# - destroy_record_params: Permits and returns the parameters required for deleting a record.
# - create_record_params: Permits and returns the parameters required for creating a new record.

class RecordsController < ApplicationController
  # Disable CSRF protection for this controller because we are not using forms
  skip_before_action :verify_authenticity_token, only: [:create, :destroy_by_attributes]

  # Rescue from StandardError globally for this controller
  rescue_from StandardError, with: :handle_standard_error
  rescue_from ArgumentError, with: :handle_argument_error

  def index
      # Get pagination parameters from the request
      page = params[:page].to_i > 0 ? params[:page].to_i : 1
      per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : PER_PAGE

      result = google_sheets_service.fetch_records_from_sheet(page, per_page)
      records = result[:records]
      total_records = result[:total_records]
      
      pagination = {
        page: page,
        per_page: per_page,
        total_records: total_records
      }
      Rails.logger.info("Records fetched: #{records.inspect}")
      render json: { records: records, pagination: pagination }, status: :ok
  end

  def create
    # Extract and validate parameters from JSON input
    new_row_params = create_record_params

    # Convert ActionController::Parameters to a hash with symbolized keys
    new_row_params = new_row_params.to_h.symbolize_keys

    if google_sheets_service.create_new_record(new_row_params)
      render json: { message: 'Row added successfully' }, status: :created
    else
      render json: { error: 'Failed to add new row' }, status: :unprocessable_entity  
    end
  end

  def destroy_by_attributes
    # Extract and validate parameters from JSON input
    delete_params = destroy_record_params

    # Convert ActionController::Parameters to a hash with symbolized keys
    delete_params = delete_params.to_h.symbolize_keys

    Rails.logger.info("Records to be deleted: #{delete_params.inspect}")
    
    # Delete the record from the sheet
    if google_sheets_service.delete_records_from_sheet(delete_params)
      render json: { message: 'Row deleted successfully' }, status: :ok
    else
      render json: { error: 'Record not found' }, status: :not_found
    end
  end

  private

  def google_sheets_service
    @google_sheets_service ||= GoogleSheetsService.new
  end

  # Handle generic errors
  def handle_standard_error(exception)
    Rails.logger.error("Error: #{exception.message}")
    render json: { error: 'An error occurred. Please try again later.' }, status: :internal_server_error
  end

  # Handle argument-related errors
  def handle_argument_error(exception)
    Rails.logger.error("Argument Error: #{exception.message}")
    render json: { error: exception.message }, status: :unprocessable_entity
  end

  def destroy_record_params
    params.require(:record).permit(:date, :description, :category, :sub_category, :amount, :remark)
  end
    
  def create_record_params
    params.require(:record).permit(:date, :description, :category, :sub_category, :amount, :remark)
  end
end
