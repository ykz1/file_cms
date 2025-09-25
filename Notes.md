3. Adding Index Page

  Requirement: On home page, display list of documents

  Implementation: 
  - Make 3 files into a 'data' directory
  - In app.rb: create an array of hashes which save the name and filepath of all files in 'data' directory
  - In index.erb: list out array's filenames

4. Viewing text files

  Requirement:
  1. add links to list of documents on home page
  2. links should work, and each page should display the file contents
  3. links should simply be filenames, so users can access directly by typing filename into url
  4. render text files as plain text on page

  Implementation:
  - add content to files
  - add a route to read and display contents of files onto page
  - add links to pages on homepage 

5. Adding Tests

  Requirements: write tests for existing routes

  Implementation:
  - add required gems to Gemfile: minitest, minitest-reporters, rack-test. Then install
  - create tests folder and test .rb file
  - test route '/'
    - response code 200
    - content type
    - all files are listed
    - all files have expected links
  - test route '/:file'
    - response code 200
    - page content matches file content
    - bad route redirects to home page

6. Handling Request for Nonexistent Documents
