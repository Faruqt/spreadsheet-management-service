require 'google_drive'
require 'json'

class GoogleSheetsService
  def initialize
    credentials_json = ENV['GOOGLE_SHEETS_CREDENTIALS']
    credentials = JSON.parse(credentials_json)
    @session = GoogleDrive::Session.from_config("config/google_sheets/credentials.json")
  end

  def read_sheet(spreadsheet_key, worksheet_title)
    spreadsheet = @session.spreadsheet_by_key(spreadsheet_key)
    worksheet = spreadsheet.worksheet_by_title(worksheet_title)
    worksheet.rows
  end

  def write_sheet(spreadsheet_key, worksheet_title, rows)
    spreadsheet = @session.spreadsheet_by_key(spreadsheet_key)
    worksheet = spreadsheet.worksheet_by_title(worksheet_title)
    worksheet.insert_rows(worksheet.num_rows + 1, rows)
    worksheet.save
  end

  def update_sheet(spreadsheet_key, worksheet_title, row_number, row)
    spreadsheet = @session.spreadsheet_by_key(spreadsheet_key)
    worksheet = spreadsheet.worksheet_by_title(worksheet_title)
    worksheet[row_number, 1] = row
    worksheet.save
  end

def delete_row(spreadsheet_key, worksheet_title, row_number)
    spreadsheet = @session.spreadsheet_by_key(spreadsheet_key)
    worksheet = spreadsheet.worksheet_by_title(worksheet_title)
    worksheet.delete_rows(row_number, 1) 
    worksheet.save
  end

end