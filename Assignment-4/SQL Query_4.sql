-- Create StudentDetails table first
CREATE TABLE StudentDetails (
    StudentId INT PRIMARY KEY,
    StudentName NVARCHAR(100),
    GPA FLOAT,
    Branch NVARCHAR(50),
    Section NVARCHAR(50)
);

-- Create SubjectDetails table
CREATE TABLE SubjectDetails (
    SubjectId NVARCHAR(50) PRIMARY KEY,
    SubjectName NVARCHAR(100),
    MaxSeats INT,
    RemainingSeats INT
);

-- Create StudentPreference table after StudentDetails and SubjectDetails
CREATE TABLE StudentPreference (
    StudentId INT,
    SubjectId NVARCHAR(50),
    Preference INT,
    PRIMARY KEY (StudentId, SubjectId, Preference),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId)
);

-- Create Allotments table
CREATE TABLE Allotments (
    SubjectId NVARCHAR(50),
    StudentId INT,
    PRIMARY KEY (SubjectId, StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);

-- Create UnallotedStudents table
CREATE TABLE UnallotedStudents (
    StudentId INT PRIMARY KEY,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);

-- Insert data into StudentDetails
INSERT INTO StudentDetails (StudentId, StudentName, GPA, Branch, Section) VALUES
(159103036, 'Mohit Agarwal', 8.9, 'CCE', 'A'),
(159103037, 'Rohit Agarwal', 5.2, 'CCE', 'A'),
(159103038, 'Shohit Garg', 7.1, 'CCE', 'B'),
(159103039, 'Mrinal Malhotra', 7.9, 'CCE', 'A'),
(159103040, 'Mehreet Singh', 5.6, 'CCE', 'A'),
(159103041, 'Arjun Tehlan', 9.2, 'CCE', 'B');

-- Insert data into SubjectDetails
INSERT INTO SubjectDetails (SubjectId, SubjectName, MaxSeats, RemainingSeats) VALUES
('PO1491', 'Basics of Political Science', 60, 2),
('PO1492', 'Basics of Accounting', 120, 119),
('PO1493', 'Basics of Financial Markets', 90, 90),
('PO1494', 'Eco philosophy', 60, 50),
('PO1495', 'Automotive Trends', 60, 60);

-- Insert data into StudentPreference
INSERT INTO StudentPreference (StudentId, SubjectId, Preference) VALUES
(159103036, 'PO1491', 1),
(159103036, 'PO1492', 2),
(159103036, 'PO1493', 3),
(159103036, 'PO1494', 4),
(159103036, 'PO1495', 5),

(159103037, 'PO1492', 1),
(159103037, 'PO1493', 2),
(159103037, 'PO1494', 3),
(159103037, 'PO1495', 4),
(159103037, 'PO1491', 5),

(159103038, 'PO1493', 1),
(159103038, 'PO1494', 2),
(159103038, 'PO1495', 3),
(159103038, 'PO1491', 4),
(159103038, 'PO1492', 5),

(159103039, 'PO1494', 1),
(159103039, 'PO1495', 2),
(159103039, 'PO1491', 3),
(159103039, 'PO1492', 4),
(159103039, 'PO1493', 5),

(159103040, 'PO1495', 1),
(159103040, 'PO1491', 2),
(159103040, 'PO1492', 3),
(159103040, 'PO1493', 4),
(159103040, 'PO1494', 5),

(159103041, 'PO1491', 1),
(159103041, 'PO1492', 2),
(159103041, 'PO1493', 3),
(159103041, 'PO1494', 4),
(159103041, 'PO1495', 5);

-- STEP 3: Create stored procedure
GO
CREATE PROCEDURE AllocateElectives
AS
BEGIN
    DECLARE @StudentId INT, @SubjectId NVARCHAR(50), @Preference INT, @GPA FLOAT;

    -- Temporary table to hold sorted students
    CREATE TABLE #SortedStudents (
        StudentId INT,
        GPA FLOAT
    );

    -- Insert students sorted by GPA
    INSERT INTO #SortedStudents (StudentId, GPA)
    SELECT StudentId, GPA
    FROM StudentDetails
    ORDER BY GPA DESC;

    -- Cursor to iterate over each student
    DECLARE student_cursor CURSOR FOR
    SELECT StudentId, GPA
    FROM #SortedStudents;

    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @StudentId, @GPA;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Allotted BIT = 0;
        
        -- Cursor to iterate over each student's preferences
        DECLARE preference_cursor CURSOR FOR
        SELECT SubjectId, Preference
        FROM StudentPreference
        WHERE StudentId = @StudentId
        ORDER BY Preference;

        OPEN preference_cursor;
        FETCH NEXT FROM preference_cursor INTO @SubjectId, @Preference;

        WHILE @@FETCH_STATUS = 0 AND @Allotted = 0
        BEGIN
            -- Check if the subject has available seats
            IF EXISTS (SELECT 1 FROM SubjectDetails WHERE SubjectId = @SubjectId AND RemainingSeats > 0)
            BEGIN
                -- Allocate the subject to the student
                INSERT INTO Allotments (SubjectId, StudentId) VALUES (@SubjectId, @StudentId);

                -- Decrement the remaining seats for the subject
                UPDATE SubjectDetails SET RemainingSeats = RemainingSeats - 1 WHERE SubjectId = @SubjectId;

                SET @Allotted = 1;
            END

            FETCH NEXT FROM preference_cursor INTO @SubjectId, @Preference;
        END

        CLOSE preference_cursor;
        DEALLOCATE preference_cursor;

        -- If student was not allotted any subject
        IF @Allotted = 0
        BEGIN
            INSERT INTO UnallotedStudents (StudentId) VALUES (@StudentId);
        END

        FETCH NEXT FROM student_cursor INTO @StudentId, @GPA;
    END

    CLOSE student_cursor;
    DEALLOCATE student_cursor;

    -- Drop the temporary table
    DROP TABLE #SortedStudents;
END;



EXEC AllocateElectives;


-- Check Allotments
SELECT * FROM Allotments;

-- Check UnallotedStudents
SELECT * FROM UnallotedStudents;

SELECT * FROM SubjectDetails;

SELECT * FROM UnallotedStudents;