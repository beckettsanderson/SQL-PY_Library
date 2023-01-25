# SQL-PY_Library

Created a virtual library linked to a books database in SQL. The library operates within a python terminal as an online library website typically would. The library 
provides user functionality as either a librarian or a member. The librarian can handle more administrative tasks such as adding or removing books from the library, 
modifying books already in the library, and creating and maintaining book clubs within the library. The members are guests in the library and as such their
functionality includes tasks such as creating an account with the library, borrowing and returning books, and joining book clubs.


### Technical Steps
1. Have Spyder (Python IDE) and mySQL workbench downloaded

2. Read in the mySQL dump file (library_db_dump.sql)

3. Open “library.py” in the Python interpreter of your choice

4. Change the host, username, password in lines 46-48 to match your connection

5. Run “library.py”

6. Explore library database and its features (see User Flow section in final report for feature options) using some of the following data examples:

        a. Librarian (login)
              username: “testUser”, password: “pass1234”
        b. Member (login)
              username: “testUser”, password: “pass1234”
        c. Book
              ISBN: “9573860998237”, Title: “A Study in Scarlet”
        d. Author
              Name: “Arthur Conan Doyle”, Books Written: 2
        e. Reading Club
              Name: “Husky Book Club”
