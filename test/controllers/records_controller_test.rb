require "test_helper"

class RecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @google_sheets_service = mock('GoogleSheetsService')
    RecordsController.any_instance.stubs(:google_sheets_service).returns(@google_sheets_service)
    @sample_records = [
      { date: "2024-10-23", description: "Sample record", category: "Income", sub_category: "Salary", amount: "5000", remark: "October salary" },
      { date: "2024-11-01", description: "Freelance project", category: "Income", sub_category: "Freelance", amount: "1500", remark: "Project payment" },
      { date: "2024-11-15", description: "Groceries", category: "Expense", sub_category: "Food", amount: "200", remark: "Weekly groceries" },
      { date: "2024-11-20", description: "Electricity bill", category: "Expense", sub_category: "Utilities", amount: "100", remark: "Monthly electricity bill" },
      { date: "2024-11-25", description: "Gym membership", category: "Expense", sub_category: "Health", amount: "50", remark: "Monthly gym membership" }
    ]
  end

  test "should get index" do
    # Mock the fetch_records_from_sheet method
    @google_sheets_service.expects(:fetch_records_from_sheet).with(1, PER_PAGE).returns({
      records: @sample_records,
      total_records: @sample_records.length
    })

    # Make the GET request to the index action
    get records_url, params: { page: 1, per_page: PER_PAGE }

    # Assert the response
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['pagination']['page']
    assert_equal PER_PAGE, json_response['pagination']['per_page']
    assert_equal 5, json_response['pagination']['total_records']
    assert_equal "Sample record", json_response['records'][0]['description']
    assert_equal "Freelance project", json_response['records'][1]['description']
    assert_equal "Groceries", json_response['records'][2]['description']
    assert_equal "Electricity bill", json_response['records'][3]['description']
    assert_equal "Gym membership", json_response['records'][4]['description']
    assert_equal "5000", json_response['records'][0]['amount']
    assert_equal "1500", json_response['records'][1]['amount']
    assert_equal "200", json_response['records'][2]['amount']
  end

  test "should create record" do
    # Mock the create_new_record method
    @google_sheets_service.expects(:create_new_record).with(@sample_records[0]).returns(true)

    # Make the POST request to the create action
    post records_url, params: { record: @sample_records[0] }

    # Assert the response
    assert_response :created
    assert_equal "Row added successfully", JSON.parse(response.body)['message']
  end

  test "should not create record if record creation fails" do
    # Mock the create_new_record method to return false
    @google_sheets_service.expects(:create_new_record).with(@sample_records[0]).returns(false)

    # Make the POST request to the create action
    post records_url, params: { record: @sample_records[0] }

    # Assert the response
    assert_response :unprocessable_entity
    assert_equal "Failed to add new row", JSON.parse(response.body)['error']
  end

  test "should not create record with invalid parameters" do
    # Mock the create_new_record method to not be called
    @google_sheets_service.expects(:create_new_record).never

    # Make the POST request to the create action with invalid parameters
    post records_url, params: { record: { } }

    # Assert the response
    assert_response :internal_server_error
    assert_equal "An error occurred. Please try again later.", JSON.parse(response.body)['error']
  end

  test "should destroy record by attributes" do
    # Mock the delete_records_from_sheet method
    @google_sheets_service.expects(:delete_records_from_sheet).with(@sample_records[0]).returns(true)

    # Make the DELETE request to the destroy_by_attributes action
    delete records_url, params: { record: @sample_records[0] }

    # Assert the response
    assert_response :ok
    assert_equal "Row deleted successfully", JSON.parse(response.body)['message']
  end

  test "should not destroy record if not found" do
    # Mock the delete_records_from_sheet method to return false
    @google_sheets_service.expects(:delete_records_from_sheet).with(@sample_records[0]).returns(false)

    # Make the DELETE request to the destroy_by_attributes action
    delete records_url, params: { record: @sample_records[0] }

    # Assert the response
    assert_response :not_found
    assert_equal "Record not found", JSON.parse(response.body)['error']
  end

end
