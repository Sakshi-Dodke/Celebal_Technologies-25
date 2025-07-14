-- Create  table TimeDimension

CREATE TABLE TimeDimension (
    [Date] DATE PRIMARY KEY,
    [Day] INT,
    [Month] INT,
    [MonthName] VARCHAR(20),
    [Quarter] INT,
    [Year] INT,
    [WeekdayName] VARCHAR(20),
    [IsWeekend] BIT,
    [DayOfWeek] INT,
    [DayOfYear] INT,
    [WeekOfYear] INT,
    [IsHoliday] BIT
);

-- CREATE Stored Procedure PopulateTimeDimension

GO
CREATE PROCEDURE PopulateTimeDimension
    @InputDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(YEAR(@InputDate), 1, 1);
    DECLARE @EndDate DATE = DATEFROMPARTS(YEAR(@InputDate), 12, 31);

    ;WITH DateSequence AS (
        SELECT @StartDate AS DateValue
        UNION ALL
        SELECT DATEADD(DAY, 1, DateValue)
        FROM DateSequence
        WHERE DateValue < @EndDate
    )
    INSERT INTO TimeDimension (
        [Date],
        [Day],
        [Month],
        [MonthName],
        [Quarter],
        [Year],
        [WeekdayName],
        [IsWeekend],
        [DayOfWeek],
        [DayOfYear],
        [WeekOfYear],
        [IsHoliday]
    )
    SELECT
        DateValue AS [Date],
        DAY(DateValue) AS [Day],
        MONTH(DateValue) AS [Month],
        DATENAME(MONTH, DateValue) AS [MonthName],
        DATEPART(QUARTER, DateValue) AS [Quarter],
        YEAR(DateValue) AS [Year],
        DATENAME(WEEKDAY, DateValue) AS [WeekdayName],
        CASE 
            WHEN DATENAME(WEEKDAY, DateValue) IN ('Saturday', 'Sunday') THEN 1 
            ELSE 0 
        END AS [IsWeekend],
        DATEPART(WEEKDAY, DateValue) AS [DayOfWeek],
        DATEPART(DAYOFYEAR, DateValue) AS [DayOfYear],
        DATEPART(WEEK, DateValue) AS [WeekOfYear],
        0 AS [IsHoliday]  -- default to 0
    FROM DateSequence
    OPTION (MAXRECURSION 366);
END

--View the Output

SELECT * FROM TimeDimension
WHERE [Year] = 2020
ORDER BY [Date];
