USE HolidayFunDB;
GO

-- RE-DECLARE TYPES IF THEY ARE NOT FOUND
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'ServicePkgList')
    CREATE TYPE ServicePkgList AS TABLE (
        AdvertisedID INT,
        Quantity INT,
        StartDate DATE,
        EndDate DATE
    );

IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'GuestListType')
    CREATE TYPE GuestListType AS TABLE (
        FullName NVARCHAR(100),
        Address NVARCHAR(200),
        Phone NVARCHAR(20),
        Email NVARCHAR(100)
    );
GO

-- NOW RUN THE TEST
DECLARE @NewID INT;
DECLARE @Items ServicePkgList;
DECLARE @Guests GuestListType;

-- TEST CASE 1: Success
INSERT INTO @Items VALUES (1, 1, '2026-12-01', '2026-12-05');
INSERT INTO @Guests VALUES ('John Tester', '1 Main St', '0290000000', 'john@test.com');

EXEC usp_makeReservation 
    @CustomerName = 'John Tester',
    @Address = '1 Main St',
    @Phone = '0290000000',
    @Email = 'john@test.com',
    @ItemList = @Items,
    @GuestList = @Guests,
    @ReservationID = @NewID OUTPUT;

SELECT 'New Reservation Created' AS Status, @NewID AS ReservationID;
SELECT * FROM Reservation WHERE ReservationID = @NewID;
GO
