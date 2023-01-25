# -*- coding: utf-8 -*-
"""
Created on Tue Apr 19 13:58:59 2022

@author: Beckett Sanderson
         Julian Savini
         Maxwell Rizzuto
"""

import pymysql
import pandas as pd
import datetime

BOOKS = "google_books_1299.csv"
HEADERS = ["num", "title", "author", "rating", "voters", "price", "currency", 
           "description", "publisher", "page_count", "genres", "ISBN", 
           "language", "publishing_date"]

def csv_editing():
    
    # read in the books csv
    df = pd.read_csv(BOOKS)
    
    # sets columns for the data
    df.columns = HEADERS
    
    # drops columns we're not using for the database
    df = df.drop(["num", "price", "rating", "voters", 
                  "currency", "language"], axis = 1)
    
    ind_to_drop = []
    
    # loops through every row of the data frame
    for ind in df.index:
        
        # check if the ISBN number is original pages instead of an int
        if df["ISBN"][ind] == "Original pages" or \
            df["ISBN"][ind] == "Flowing text" or \
            df["ISBN"][ind] == "Flowing text, Google-generated PDF":
            
            # adds the rows that have original pages to a list
            ind_to_drop.append(ind)
            continue
        
        # checks if the genre has the value of the string none
        if df["genres"][ind] == "none":
            
            # sets the genre to null
            df.loc[ind, "genres"] = "NULL"
            
        # sets the date column into datetime format
        date_obj = datetime.datetime.strptime(df['publishing_date'][ind], '%d-%b-%y')
        df['publishing_date'][ind] = datetime.datetime.strftime(date_obj, '%Y-%m-%d')
    
    # remove the rows with original pages
    df = df.drop(labels = ind_to_drop)
    print(df.head())
    
    # creates a new csv with the cleaned data
    df.to_csv("updated_google_books_1299.csv", index=False)


def print_book(book):
    """
    Prints out all the details for a book

    Parameters
    ----------
    book : row of cursor
        a row containing all the info from the books.

    Returns
    -------
    None.

    """
    available = ""
    if book['available'] == 1:
        available = "Yes"
    else: 
        available = "No"
    
    print("\n", book['title'], ", ISBN:", book['isbn'], ",",  book['page_count'], "pages, Available:", available)


def Main():
    
    # csv_editing(BOOKS)
    try:
        cnx = pymysql.connect(host = 'localhost',
                              user = "root",
                              password = "FILL PASSWORD HERE",
                              db = 'library', charset = 'utf8mb4',
                              cursorclass = pymysql.cursors.DictCursor)
    
    except pymysql.err.OperationalError as e:
        print('Error: %d: %s' % (e.args[0], e.args[1]))
        
    try:
        user_type = ""
        while user_type.upper() != "LIBRARIAN" and user_type.upper() != "MEMBER":
            
            # get input of user type
            user_type = input("Input LIBRARIAN to enter as librarian. "
                              "Input MEMBER to enter as a member. \n  >>>> ")
            cursor = cnx.cursor()
            
            # login if user is librarian
            if user_type.upper() == "LIBRARIAN":
                gate = "closed"
                while gate != "open":
                    cursor.execute('SELECT username, password FROM librarian')
                    username = input("USERNAME: \n  >>>> ")
                    password = input("PASSWORD: \n  >>>> ")
                    for row in cursor:
                        if username == row["username"]:
                            if password == row["password"]:
                                gate = "open"
                    if gate == "closed":
                        print("\nInvalid username or password. Please try again:")
                cursor.close()
                
                
                # while the user does not type logout, request what they would like
                decision = ""
                while decision != "LOGOUT":
                    program_cur = cnx.cursor()  
                    
                    # get what activity the user would like to perform
                    decision = input("ENTER: \'CREATE BOOKCLUB\', \'MODIFY BOOK\', \'ADD BOOK\', "
                                     "\'REMOVE BOOK\', \'ASSIGN NEW BOOK\', OR \'LOGOUT\' \n  >>> ")
                    
                    # create a new bookclub
                    if decision.upper() == "CREATE BOOKCLUB":
                        club_name = input("Enter the name of the book club: \n  >>>> ")
                        date_founded = datetime.datetime.today()
                        date_founded = date_founded.strftime("%Y-%m-%d")
                        
                        program_cur.callproc("create_reading_club", (club_name, date_founded, username))
                        cnx.commit()
                        print("\nYou have created the bookclub!")
                    
                    # assign a new book to the book club
                    elif decision.upper() == "ASSIGN NEW BOOK":
                        club_name = input("Enter the name of the book club: \n  >>>> ")
                        isbn = input("Enter the isbn of the new book: \n  >>>>")
                        
                        program_cur.callproc("assign_new_book", (club_name, isbn))
                        cnx.commit()
                        print("\nYou have assigned a book to the bookclub!")
                    
                    # modify the description of a book
                    elif decision.upper() == "MODIFY BOOK":
                        
                        choice = input("ENTER \'ADD GENRE\', \'REMOVE GENRE\', \'CHANGE DESCRIPTION\', or \'BACK\' \n  >>> ")
                            
                        # add a genre to a book
                        if choice.upper() == "ADD GENRE":
                            isbn = input("Enter the isbn of the book: \n  >>>> ")
                            genre = input("Enter the genre to add to the book: \n  >>>> ")
                            
                            program_cur.callproc("add_book_genre", (isbn, genre))
                            cnx.commit()
                            print("\nYou have added the genre!")
                            
                        # remove a genre from a book
                        elif choice.upper() == "REMOVE GENRE":
                            isbn = input("Enter the isbn of the book: \n  >>>> ")
                            genre = input("Enter the genre to remove from the book: \n  >>>> ")
                            
                            program_cur.callproc("remove_book_genre", (isbn, genre))
                            cnx.commit()
                            print("\nYou have removed the genre!")
                                
                        # change the description of a book
                        elif choice.upper() == "CHANGE DESCRIPTION":
                            isbn = input("Enter the isbn of the book: \n  >>>> ")
                            description = input("Enter the new description of the book. There is a 150 character limit. \n  >>>> ")
                            
                            program_cur.callproc("edit_book_description", (isbn, description))
                            cnx.commit()
                            print("\nThe description has been changed!")
                        
                        elif choice.upper() == "BACK":
                            continue
                        
                        else:
                            print("\nSorry that's not a valid input. Please try again:")
                            
                    # add a new book to the library
                    elif decision.upper() == "ADD BOOK":
                        isbn = input("Enter the ISBN of the book: \n  >>>> ")
                        title = input("Enter the title of the book: \n  >>>> ")
                        page_count = input("Enter the number of pages of the book: \n  >>>> ")
                        publisher = input("Enter the publisher of the book: \n  >>>> ")
                        publication_date = input("Enter the publication date of the book (Format: YYYY-MM-DD): \n  >>>> ")
                        author = input("Enter the author of the book: \n  >>>> ")
                        genre = input("Enter the genre of the book: \n  >>>> ")
                        
                        program_cur.callproc("add_book", (isbn, title, page_count, publisher, publication_date, author, genre))
                        cnx.commit()
                        print("\nThe book has been added!")
                    
                    # remove a book from the library
                    elif decision.upper() == "REMOVE BOOK":
                        isbn = input("Enter the ISBN of the book: \n  >>>> ")
                        
                        program_cur.callproc("remove_book", [isbn])
                        cnx.commit()
                        print("\nThe book has been removed!")
                    
                    # logout of the system. Program terminates.
                    elif decision.upper() != "LOGOUT":
                        print("\nSorry that's not a valid input. Please try again:")
                    
                    else:
                        print("\nThanks for visiting our library!")
                        break
                    
                    program_cur.close()
            
            # if user is a member, ask them to either create of login an account
            elif user_type.upper() == "MEMBER":
                new_type = ""
                while new_type.upper() != "CREATE" and new_type.upper() != "LOGIN":
                    
                    new_type = input("Input CREATE if you would like to make an account. "
                                     "Input LOGIN if you would like to login in to your"
                                     " account: \n  >>>> ")
                    program_cur = cnx.cursor()
                    
                    # ask user to create an account
                    if new_type.upper() == "CREATE":
                        username = input("NEW USERNAME: \n  >>>> ")
                        password = input("NEW PASSWORD: \n  >>>> ")
                        first_name = input("FIRST NAME: \n  >>>> ")
                        last_name = input("LAST NAME: \n  >>>> ")
                        program_cur = cnx.cursor()
                        
                        program_cur.callproc("create_member", (username, password, first_name, last_name))
                        cnx.commit()
                        program_cur.close()
                    
                    # ask user to login
                    elif new_type.upper() == "LOGIN":
                        gate = "closed"
                        while gate != "open":
                            username = input("USERNAME: \n  >>>> ")
                            password = input("PASSWORD: \n  >>>> ")
                            cursor.execute('SELECT username, password FROM member')
                            for row in cursor:
                                if username == row["username"]:
                                    if password == row["password"]:
                                        gate = "open"
                            if gate == "closed":
                                print("\nInvalid username or password. Please try again:")
                    
                    else:
                        print("\nSorry that's not a valid input. Please try again:")
                    
                # while the user does not type logout, they are requested what they would like to do
                decision = ""
                while decision != "LOGOUT":
                    program_cur = cnx.cursor()  
                    
                    # get what activity the user would like to perform
                    decision = input("ENTER: \'BORROW BOOK\', \'RETURN BOOK\', \'FILTER BOOKS\', \'JOIN BOOKCLUB\', \'LEAVE BOOKCLUB\', OR \'LOGOUT\' \n  >>> ")
                    
                    # checkout a book
                    if decision.upper() == "BORROW BOOK":
                        isbn = input("Enter the isbn of the book to borrow: \n  >>>> ")
                        program_cur.execute("SELECT available FROM book WHERE isbn = "+isbn)
                        for row in program_cur:    
                            if row['available'] == 1:
                                print("\nYour book has been checked out. Happy reading!")
                            else:
                                print("\nSorry, this book is currently checked out. Try again later!")
                        
                        program_cur.callproc("borrow_book", (username, isbn))
                        cnx.commit()
                    
                    # return a book
                    elif decision.upper() == "RETURN BOOK":
                        isbn = input("Enter the isbn of the book to return: \n  >>>> ")
                        
                        program_cur.callproc("return_book", (username, isbn))
                        cnx.commit()
                        print("\nThanks! Your book has been returned.")
                    
                    # filter a book
                    elif decision.upper() == "FILTER BOOKS":
                        choice = input("ENTER \'PAGE COUNT\', \'GENRE\', \'TITLE\', \'AUTHOR\', or \'BACK\' \n  >>> ")
                        
                        # filter a book by page count
                        if choice.upper() == "PAGE COUNT":
                            max_p = input("Enter the maximum pages: \n  >>>> ")
                            min_p = input("Enter the minimum pages: \n  >>>> ")
                            select_cur = cnx.cursor()
                            select_cur.execute("SELECT title, isbn, page_count, available FROM book WHERE page_count <="+max_p+" AND page_count >= "+min_p)
                            fetched = select_cur.fetchall()
                            for row in fetched:
                                print_book(row)
                            if len(fetched) == 0:
                                print("\nSorry, no results were found. Please try again.")
                                
                        # filter a book by title
                        elif choice.upper() == "TITLE":
                            title = input("Enter the title of the book: \n >>>> ")
                            select_cur = cnx.cursor()
                            select_cur.execute("SELECT title, isbn, page_count, available FROM book WHERE title LIKE '%"+title+"%'")
                            fetched = select_cur.fetchall()
                            for row in fetched:
                                print_book(row)
                            if len(fetched) == 0:
                                print("\nSorry, no results were found. Please try again.")
                                
                        # filter a book by genre
                        elif choice.upper() == "GENRE":
                            genre = input("Enter the genre of the book: \n  >>>> ")
                            select_cur = cnx.cursor()
                            select_cur.execute("SELECT title, isbn, page_count, available FROM book JOIN book_genre USING(isbn) WHERE genre = '"+genre+"'")
                            fetched = select_cur.fetchall()
                            for row in fetched:
                                print_book(row)
                            if len(fetched) == 0:
                                print("\nSorry, no results were found. Please try again.")
                        
                        # filter a book by author
                        elif choice.upper() == "AUTHOR":
                            author = input("Enter the author of the book: \n  >>>> ")
                            select_cur = cnx.cursor()
                            select_cur.execute("SELECT title, isbn, page_count, available FROM book JOIN book_author USING(isbn) WHERE author = '"+author+"'")
                            fetched = select_cur.fetchall()
                            for row in fetched:
                                print_book(row)
                            if len(fetched) == 0:
                                print("\nSorry, no results were found. Please try again.")
                        
                        elif choice.upper() == "BACK":
                            continue
                        
                        else:
                            print("\nSorry that's not a valid input. Please try again:")
                            
                    # join a reading club
                    elif decision.upper() == "JOIN BOOKCLUB":
                        club_name = input("Enter the name of the bookclub: \n  >>>> ")
                        
                        program_cur.callproc("join_reading_club", (username, club_name))
                        cnx.commit()
                        print("\nYou have joined the bookclub!")
                    
                    # leave a reading club
                    elif decision.upper() == "LEAVE BOOKCLUB":
                        club_name = input("Enter the name of the bookclub: \n  >>>> ")
                         
                        program_cur.callproc("leave_reading_club", (username, club_name))
                        cnx.commit()
                        print("\nYou have left the bookclub!")
                    
                    # logout. code terminates.
                    elif decision.upper() != "LOGOUT":
                        print("\nSorry that's not a valid input. Please try again:")
                    
                    else:
                        print("\nThanks for visiting our library!")
                        break
                    
                    program_cur.close()
                
            else:
                print("\nSorry that's not a valid input. Please try again:")
        
    except pymysql.Error as e:
        print('Error: %d: %s' % (e.args[0], e.args[1]))
        
    finally:
        cnx.close()
        
if __name__ == "__main__":
    Main()
