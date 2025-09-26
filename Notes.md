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

  Requirements: 
  - show error message for bad url lookups + redirect to home
  - reloading removes error page

  Implementation:
  - store error message in session
  - display / delete error message from layout.erb
  - write test to make sure:
    1. error message shows up
    2. redirect happens
    3. reloading leads to error message going away


7. Viewing Markdown Files

  Requirements:
  - render HTML version when file is markdown

  Implementation:
  - Change about.txt to about.md and add some markdown
  - add redcarpet to project
  - on file routes, check whether file is `.md` and if yes then render via redcarpet
  - add testing somehow...


8. Editing Document Content

  Requirements:
  - add "Edit" links on home page
  - links to '/edit' path for each file
  - show content in a textarea
  - add "save changes" button which 1) redirects to index page; and 2) show message

  Implementation:
  - add route for get `/:filename/edit`
    - figure out what textarea is and load existing content in
    - figure out how to make save changes button
    - button should send post request
  - add route for post `/:filename/edit`
    - take input from form text box 
    - overwrite appropriate file with input
    - add success and error messages
    - redirect to index page
  - add tests
    - make sure correct text is loaded into textarea
    - make sure redirect is to index
    - make sure edits are shown in updated file pages


9. Isolating Test Execution

  (skipped notes for this one)
  
10. Adding Global Style and Behavior

  Requirements:
  1. Yellow background around messages
  2. Messages disappear once reloaded
  3. Text remains plain text
  4. Entire site in sans-serif

  Implementation:
  - Add CSS 
  - Link to CSS from layout.erb

11. Favicon

12. Creating New Documents

  Requirements
  - Add "new document" link to index page
  - Create New Document route - get
  - Create New Document route - post
    - Error validation 

  Implementation
  - Add link to index
  - New Document page
    - New view template for "file_new" page
    - Add entry text box similar to edit page
    - Add create button similar to edit page
    - New route for get '/new'
  - New Document post
    - Button should send post
    - create post '/new' route
    - re-render template if error
    - otherwise create new file and redirect to index page with message
  - Tests
    - On index: new file link exists
    - On new file page
      - submitting valid new file name leads to 
        1) redirect to index
        2) file is actually created and showing on index
        3) correct message on index
        4) message goes away on reload
        5) individual page for new file loads
      - submitting invalid name
        - blank creates error
        - spaces creates error
        - existing filename creates error
        - valid name with spaces results in spaces being stripped
        - upon error, entered value is retained in input box

13. Deleting Documents

  Requirements
  - Delete buttons on index
  - Delete appropriately

  Implementation
  - Add links on index
  - Add post route for deletion
    - success message
  - Test
    