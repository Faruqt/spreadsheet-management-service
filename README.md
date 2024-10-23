# SPREADSHEET MANAGEMENT SERVICE

The Spreadsheet Management Service is a Ruby on Rails application that integrates with Google Sheets using the Google Drive API. It provides an interface for managing records, offering a convenient way to perform CRUD operations on data stored in a Google Sheets document. This service is useful for teams or individuals who prefer to manage data in Google Sheets but need additional functionality and control through a Rails app.

## Table of Contents

- [Features](#features)
- [Endpoints](#endpoints)
  - [Fetch Records](#fetch-records)
  - [Create Record](#create-record)
  - [Delete Record](#delete-record)
- [Setup](#setup)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Docker Setup](#docker-setup)
- [Error Handling](#error-handling)

## Features

- **Fetch Records**: Fetches and returns paginated records from the Google Sheets document.
- **Create Record**: Adds a new record to the Google Sheets document.
- **Delete Record**: Deletes records from the Google Sheets document based on provided attributes.

## Endpoints

### Fetch Records

- **Endpoint**: `GET /records`
- **Description**: Fetches and returns paginated records from the Google Sheets document.
- **Parameters**:
  - `page` (optional): The page number for pagination. Defaults to 1.
  - `per_page` (optional): The number of records per page. Defaults to `PER_PAGE`.
- **Response**:
  - `200 OK`: Returns the fetched records.
  ```json
    {
        "records": [
            {
            "date": "2024-10-23",
            "description": "Sample record",
            "category": "Income",
            "sub_category": "Salary",
            "amount": 5000,
            "remark": "October salary"
            }
        ],
        "pagination": {
            "page": 1,
            "per_page": 10,
            "total_pages": 5
        }
    }
    ```

### Create Record

- **Endpoint**: `POST /records`
- **Description**: Adds a new record to the Google Sheets document.
- **Parameters**:
  - `record` (required): A JSON object containing the record attributes.
    - `date`: The date of the record.
    - `description`: The description of the record.
    - `category`: The category of the record.
    - `sub_category`: The sub-category of the record.
    - `amount`: The amount of the record.
    - `remark`: Any additional remarks for the record.
- **Response**:
  - `201 Created`: Returns a success message if the record is added successfully.
  ```json
    {
        "message": "Record added successfully",
        "record": {
            "date": "2024-10-23",
            "description": "Sample record",
            "category": "Income",
            "sub_category": "Salary",
            "amount": 5000,
            "remark": "October salary"
        }
    }
    ```
  - `422 Unprocessable Entity`: Returns an error message if the record could not be added.
  ```json
    {
        "error": "Failed to add new row"
    }
    ```

### Delete Record

- **Endpoint**: `DELETE /records`
- **Description**: Deletes records from the Google Sheets document based on provided attributes.
- **Parameters**:
  - `record` (required): A JSON object containing the record attributes to match for deletion.
    - `date`: The date of the record.
    - `description`: The description of the record.
    - `category`: The category of the record.
    - `sub_category`: The sub-category of the record.
    - `amount`: The amount of the record.
    - `remark`: Any additional remarks for the record.
- **Response**:
  - `200 OK`: Returns a success message if the record is deleted successfully.
  ```json
    {
        "message": "Record deleted successfully"
    }
    ```
  - `404 Not Found`: Returns an error message if the record could not be found.
  ```json
    {
        "error": "Record not found"
    }

    ```


## Setup

### Prerequisites

- Ruby (version specified in `.ruby-version`)
- Rails
- [Create a Google Cloud Platform Service Account](https://medium.com/@matheodaly.md/create-a-google-cloud-platform-service-account-in-3-steps-7e92d8298800)
- [Enable Google Drive API](https://cloud.google.com/endpoints/docs/openapi/enable-api)
- Docker and DockerDesktop (Optional)

### Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/faruqt/spreadsheet-management-service.git
   cd spreadsheet-management-service
    ```
2. Install dependencies:
    ```sh
    bundle install
    ```

3. Set up Google Sheets API credentials:
    - Create a .env file to match the env.sample file in the root directory.
    -Add your Google Service Account json credentials obtained from the google console and other environment variables:
    ```sh
        GOOGLE_SHEET_KEY=<your-google-sheet-key>
        GOOGLE_SHEET_TITLE=<your-google-sheet-title>
        GOOGLE_SERVICE_ACCOUNT_CREDENTIALS=<your-service-account-credentials>
    ```

4. Start the Rails server:
    ```sh
    rails server
    ```

### Docker Setup
If you prefer to use Docker, follow these steps:

1. Build the Docker image and start the container using the development configuration:
   ```sh
   docker-compose -f docker-compose.dev.yml up
    ```
- This command builds the Docker image and starts the application in a container using the docker-compose.dev.yml configuration file.

## Error Handling
- **StandardError**: Triggered by unexpected system errors or issues in external API calls, returning a `500 Internal Server Error`.
- **ArgumentError**: Raised when provided parameters are invalid or missing, returning a `422 Unprocessable Entity`.


## Summary
- **Features**: Describes the main features of the application.
- **Endpoints**: Provides details about the available API endpoints, including parameters and responses.
- **Setup**: Instructions for setting up the application, including prerequisites and installation steps.
- **Error Handling**: Describes how errors are handled in the application.

This README file provides a comprehensive overview of the application, its features, and how to set it up and use it.