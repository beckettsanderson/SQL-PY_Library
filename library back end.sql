DROP DATABASE IF EXISTS library; 
CREATE DATABASE library;
USE library;

CREATE TABLE librarian (
    adminID INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(25) UNIQUE NOT NULL,
    password VARCHAR(25) NOT NULL,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL
);

CREATE TABLE `member` (
    member_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(25) UNIQUE NOT NULL,
    password VARCHAR(25) NOT NULL,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL
);

CREATE TABLE publisher (
    name VARCHAR(80) PRIMARY KEY
);

CREATE TABLE genre (
    name VARCHAR(30) PRIMARY KEY,
    description VARCHAR(100) DEFAULT NULL
);

CREATE TABLE author (
    name VARCHAR(50) PRIMARY KEY
);

CREATE TABLE book (
    isbn CHAR(13) PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    description VARCHAR(10000),
    page_count INT NOT NULL,
    available BOOL NOT NULL DEFAULT 1,
    current_holder INT,
    publisher_name VARCHAR(80) NOT NULL,
    publication_date DATE NOT NULL,
    CONSTRAINT book_publisher_fk FOREIGN KEY (publisher_name)
REFERENCES publisher (name)
        ON UPDATE CASCADE ON DELETE CASCADE,
CONSTRAINT book_holder_fk FOREIGN KEY (current_holder)
REFERENCES `member` (member_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE book_genre (
isbn CHAR(13) NOT NULL,
    genre VARCHAR(30) NOT NULL,
    PRIMARY KEY (isbn, genre),
    CONSTRAINT book_genre_isbn_fk FOREIGN KEY (isbn)
REFERENCES book (isbn)
        ON UPDATE CASCADE ON DELETE CASCADE,
CONSTRAINT book_genre_fk FOREIGN KEY (genre)
REFERENCES genre (name)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE book_author (
    author VARCHAR(50) NOT NULL,
    isbn CHAR(13) NOT NULL,
    PRIMARY KEY (author, isbn),
    CONSTRAINT book_author_id_fk FOREIGN KEY (author)
        REFERENCES author (name)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT book_author_isbn_fk FOREIGN KEY (isbn)
        REFERENCES book (isbn)
        ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE reading_club (
    club_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL UNIQUE,
    date_founded DATE NOT NULL,
    librarian INT NOT NULL,
    current_book_isbn CHAR(13) NOT NULL, 
    CONSTRAINT librarian_club_fk FOREIGN KEY (librarian)
REFERENCES librarian (adminID)
        ON UPDATE CASCADE ON DELETE CASCADE,
CONSTRAINT reading_club_isbn_fk FOREIGN KEY (current_book_isbn)
REFERENCES book (isbn)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE reading_club_members (
    club_id INT NOT NULL,
    member_id INT NOT NULL,
    CONSTRAINT member_club_id_fk FOREIGN KEY (club_id)
        REFERENCES reading_club (club_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT reading_club_member_fk FOREIGN KEY (member_id)
        REFERENCES `member` (member_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);
/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE add_book (isbn_p CHAR(13), title_p VARCHAR(500), page_count_p INT, 
 publisher_name_p VARCHAR(80), publication_date_p DATE, author_p VARCHAR(50), genre_p VARCHAR(30))
BEGIN
DECLARE publisher_check, book_check, author_check, genre_check INT;

SELECT COUNT(*) INTO publisher_check FROM publisher WHERE name = publisher_name_p;
SELECT COUNT(*) INTO book_check FROM book WHERE isbn = isbn_p;
    SELECT COUNT(*) INTO author_check FROM author WHERE name = author_p;
    SELECT COUNT(*) INTO genre_check FROM genre WHERE name = genre_p;

IF publisher_check = 0 THEN
INSERT INTO publisher (name)
VALUES (publisher_name_p);
END IF;

IF book_check = 0 THEN
INSERT INTO book (isbn, title, page_count, available, name, publication_date)
VALUES (isbn_p, title_p, page_count_p, TRUE, publisher_name_p, publication_date_p);
END IF;
    
    IF author_check = 0 THEN
INSERT INTO author (name, books_written)
        VALUES (author_p, 1);
END IF;
    
    IF genre_check = 0 THEN
INSERT INTO genre (name)
        VALUES (genre_p);
END IF;
    INSERT INTO book_author (author, isbn)
    VALUES (author_p, isbn_p);
    
    INSERT INTO book_genre (isbn, genre)
    VALUES (isbn_p, genre_p);
END$$
DELIMITER ;
/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE remove_book (isbn_p CHAR(13))

BEGIN
DECLARE book_check INT;
SELECT COUNT(*) INTO book_check FROM book WHERE isbn = isbn_p;

IF book_check <> 0 THEN
DELETE FROM book WHERE isbn = isbn_p;
        DELETE FROM book_genre WHERE isbn = isbn_p;
        DELETE FROM book_author WHERE isbn = isbn_p;
END IF;
END$$
DELIMITER ; 
-- CALL remove_book(2387569065327);
/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE change_description (isbn_p CHAR(13), description_p VARCHAR(10000))

BEGIN
DECLARE book_check INT;
SELECT COUNT(*) INTO book_check FROM book WHERE isbn = isbn_p;
    
    IF book_check = 1 THEN
UPDATE book
SET description = description_p
WHERE isbn = isbn_p;
END IF;
END$$
DELIMITER ;
-- CALL change_description (2387569065327, "Wizard wizard woooo Harry Potter, the boy who lived. dobby");
/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE add_genre (isbn_p CHAR(13), genre_p VARCHAR(30))

BEGIN
DECLARE book_check, book_genre_check INT;
    SELECT COUNT(*) INTO book_check FROM book WHERE isbn = isbn_p;
    SELECT COUNT(*) INTO book_genre_check FROM book_genre WHERE isbn = isbn_p AND genre = genre_p
IF genre_check = 0 THEN

/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE borrow_book (username_p VARCHAR(25), isbn_p CHAR(13))

BEGIN
DECLARE book_check INT;
    DECLARE availability_check INT;
    DECLARE new_member_id INT;
    SELECT COUNT(*) INTO book_check FROM book WHERE isbn = isbn_p;
    SELECT available INTO availability_check FROM book WHERE isbn = isbn_p;
    SELECT member_id INTO new_member_ID FROM `member` WHERE username = username_p;
    
    IF book_check = 1 AND availability_check = 1 THEN
UPDATE book
        SET available = 0, current_holder = new_member_id
        WHERE isbn = isbn_p;
END IF;
END$$
DELIMITER ;
/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE return_book (username_p VARCHAR(25), isbn_p CHAR(13))

BEGIN
DECLARE book_check INT;
    DECLARE holder_check INT;
    DECLARE new_member_id INT;
    SELECT COUNT(*) INTO book_check FROM book WHERE isbn = isbn_p;
    SELECT current_holder INTO holder_check FROM book WHERE isbn = isbn_p;
    SELECT member_id INTO new_member_ID FROM `member` WHERE username = username_p;
    
    IF book_check = 1 AND holder_check = new_member_id THEN
UPDATE book
        SET available = 1, current_holder = NULL
        WHERE isbn = isbn_p;
END IF;
END$$
DELIMITER ;
-- CALL return_book ("mrizzuto", 2387569065327);
/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE create_reading_club (club_name_p VARCHAR(30), date_founded_p DATE, 
 librarian_username_p VARCHAR(25), assigned_book_isbn_p CHAR(13))
BEGIN
DECLARE book_check INT;
    DECLARE librarian_id INT;
    SELECT COUNT(*) INTO book_check FROM book WHERE isbn = isbn_p;
    SELECT adminID INTO librarian_id FROM librarian WHERE username = librarian_username_p;
    
    IF book_check = 1 THEN
INSERT INTO reading_club (club_id, name, date_founded, librarian, current_book_isbn)
        VALUES (NULL, club_name_p, date_founded_p, librarian_id, assigned_book_isbn_p);
END IF;
END$$
DELIMITER ; 
/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE assign_new_book (club_id_p INT, book_isbn_p CHAR(13))

BEGIN
DECLARE book_check INT;
    DECLARE club_check INT;
    SELECT COUNT(*) INTO book_check FROM book WHERE isbn = isbn_p;
    SELECT COUNT(*) INTO club_check FROM reading_club WHERE club_id = club_id_p;
    
    IF book_check = 1 AND club_check = 1 THEN
UPDATE reading_club
        SET current_book_isbn = isbn_p
        WHERE club_id = club_id_p;
END IF;
END$$
DELIMITER ;
/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE join_reading_club (username_p VARCHAR(25), reading_club_name_p VARCHAR(30))

BEGIN
DECLARE club_exists_check INT;
    DECLARE user_exists_check INT;
    DECLARE in_club_check INT;
    DECLARE new_club_id INT;
    DECLARE new_member_id INT;
    SELECT COUNT(*) INTO club_exists_check FROM reading_club WHERE name = reading_club_name_p;
    SELECT COUNT(*) INTO user_exists_check FROM `member` WHERE username = username_p;
    
    IF club_exists_check = 1 AND user_exists_check = 1 THEN 
SELECT club_id INTO new_club_id FROM reading_club WHERE name = reading_club_name_p;
        SELECT member_id INTO new_member_id FROM `member` WHERE username = username_p;
        SELECT COUNT(*) INTO in_club_check FROM reading_club_members WHERE club_id = new_club_id AND member_id = new_member_id;
        
        IF in_club_check = 0 THEN
INSERT INTO reading_club_members (club_id, member_id)
            VALUES (new_club_id, new_member_id);
END IF;
END IF;
END$$
DELIMITER ; 
/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE leave_reading_club (username_p VARCHAR(25), reading_club_name_p VARCHAR(30))

BEGIN
DECLARE club_exists_check INT;
    DECLARE user_exists_check INT;
    DECLARE in_club_check INT;
    DECLARE new_club_id INT;
    DECLARE new_member_id INT;
    SELECT COUNT(*) INTO club_exists_check FROM reading_club WHERE name = reading_club_name_p;
    SELECT COUNT(*) INTO user_exists_check FROM `member` WHERE username = username_p;
    
    IF club_exists_check = 1 AND user_exists_check = 1 THEN 
SELECT club_id INTO new_club_id FROM reading_club WHERE name = reading_club_name_p;
        SELECT member_id INTO new_member_id FROM `member` WHERE username = username_p;
        SELECT COUNT(*) INTO in_club_check FROM reading_club_members WHERE club_id = new_club_id AND member_id = new_member_id;
        
        IF in_club_check = 1 THEN
DELETE FROM reading_club_members WHERE club_id = new_club_id AND member_id = new_member_id;
END IF;
END IF;
END$$
DELIMITER ; 
/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE create_member(username_p VARCHAR(25), password_p VARCHAR(25), 
  f_name VARCHAR(30), l_name VARCHAR(30))
  
BEGIN
DECLARE username_check INT;
    SELECT COUNT(*) INTO username_check FROM `member` WHERE username = username_p;
    
    IF username_check = 0 THEN
INSERT INTO `member` VALUES (NULL, username_p, password_p, f_name, l_name);
END IF;
END$$
DELIMITER ;
/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE create_librarian(username_p VARCHAR(25), password_p VARCHAR(25), 
  f_name VARCHAR(30), l_name VARCHAR(30))
  
BEGIN
DECLARE username_check INT;
    SELECT COUNT(*) INTO username_check FROM librarian WHERE username = username_p;
    
    IF username_check = 0 THEN
INSERT INTO `librarian` VALUES (NULL, username_p, password_p, f_name, l_name);
END IF;
END$$
DELIMITER ;
/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE initialize_author_book_count (author_name_p VARCHAR(50))

BEGIN
DECLARE column_check INT;
    DECLARE num_books_var INT;
    
    SELECT COUNT(*) INTO column_check FROM information_schema.columns
    WHERE table_name = "author" AND column_name = "books_written";
    
    IF column_check = 0 THEN
ALTER TABLE author
ADD books_written INT;
END IF;
    
    SELECT COUNT(*) INTO num_books_var FROM book_author WHERE author = author_name_p;
    UPDATE author
SET books_written = num_books_var
        WHERE name = author_name_p;
END$$
/****************************************************************************************************************/
CREATE PROCEDURE loop_books_written ()

BEGIN
DECLARE author_name_var VARCHAR(50);
    DECLARE row_not_found INT;
    
    DECLARE author_name_c CURSOR FOR
SELECT name FROM author;
DECLARE CONTINUE HANDLER FOR NOT FOUND
SET row_not_found = TRUE;
SET row_not_found = FALSE;
OPEN author_name_c;
WHILE row_not_found = FALSE DO
FETCH author_name_c INTO author_name_var;
CALL initialize_author_book_count(author_name_var);
END WHILE;
END$$
DELIMITER ;
CALL loop_books_written();
/****************************************************************************************************************/
DELIMITER $$
CREATE PROCEDURE initialize_publisher_book_count (publisher_p VARCHAR(80))

BEGIN
DECLARE column_check INT;
    DECLARE num_books_var INT;
    
    SELECT COUNT(*) INTO column_check FROM information_schema.columns
    WHERE table_name = "publisher" AND column_name = "books_published";
    
    IF column_check = 0 THEN
ALTER TABLE publisher
ADD books_published INT;
END IF;
    
    SELECT COUNT(*) INTO num_books_var FROM book WHERE publisher_name = publisher_p;
    UPDATE publisher
SET books_published = num_books_var
        WHERE name = publisher_p;
END$$
/****************************************************************************************************************/
CREATE PROCEDURE loop_books_published ()
BEGIN
DECLARE publisher_name_var VARCHAR(80);
    DECLARE row_not_found INT;
    
    DECLARE publisher_name_c CURSOR FOR
SELECT name FROM publisher;
DECLARE CONTINUE HANDLER FOR NOT FOUND
SET row_not_found = TRUE;
SET row_not_found = FALSE;
OPEN publisher_name_c;
WHILE row_not_found = FALSE DO
FETCH publisher_name_c INTO publisher_name_var;
CALL initialize_publisher_book_count(publisher_name_var);
END WHILE;
END$$
DELIMITER ;
CALL loop_books_published();


/*
DELIMITER $$
CREATE PROCEDURE initialize_written ()
BEGIN
DECLARE written_check INT;
SELECT COUNT(*) INTO written_check FROM information_schema.columns
    WHERE table_name = "author" AND column_name = "books_written";
    IF written_check = 0 THEN
ALTER TABLE author
ADD books_written INT;
END IF;
END$$

CREATE PROCEDURE initialize_published ()
BEGIN
DECLARE published_check INT;
SELECT COUNT(*) INTO published_check FROM information_schema.columns
    WHERE table_name = "publisher" AND column_name = "books_published";
    IF published_check = 0 THEN
ALTER TABLE publisher
ADD books_published INT;
END IF;  
END$$

DELIMITER ; 
CALL initialize_written;
CALL initialize_published;
*/


/****************************************************************************************************************/
DELIMITER $$
CREATE TRIGGER books_after_insert
AFTER INSERT ON book
FOR EACH ROW
BEGIN
    DECLARE author_var VARCHAR(50);
    SELECT author INTO author_var FROM book_author WHERE isbn = NEW.isbn;
    UPDATE author
SET books_written = (SELECT COUNT(*) FROM book_author WHERE author = author_var)
        WHERE name = author_var;

    UPDATE publisher
SET books_published = (SELECT COUNT(*) FROM book WHERE publisher_name = NEW.publisher_name)
        WHERE name = NEW.publisher_name;
END$$
/****************************************************************************************************************/
/*
CREATE TRIGGER ExpenseSum AFTER INSERT ON ExpenseTable FOR EACH ROW
BEGIN
    UPDATE ProjectsTable P
    SET ExpenseTotal = 
    (SELECT SUM(ExpenseAmount) from ExpenseTable
    where ExpenseTable.ProjectID= P.ProjectID)
    where P.ProjectID = New.ProjectID;
END
*/

