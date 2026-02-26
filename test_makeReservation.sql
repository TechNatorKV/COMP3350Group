USE HolidayFunDB;
GO

/*
=============================================================
Test Script for usp_makeReservation
Tests:
1. Successful reservation
2. Capacity failure scenario
=============================================================
*/

DECLARE @NewReservationID INT;
DECLARE @Items ServicePkgList;
DECLARE @Guests GuestListType;

/* ==========================================================
TEST CASE 1 – SUCCESS
========================================================== */

INSERT INTO @Items VALUES (1, 1, '2026-12-01', '2026-12-05');

INSERT INTO @Guests VALUES 
('John Guest','1 Main St','0400000000','guest1@test.com'),
('Mary Guest','2 Main St','0411111111','guest2@test.com');

EXEC usp_makeReservation
    @CustomerName = 'John Tester',
    @Address = '1 Main St',
    @Phone = '0290000000',
    @Email = 'john@test.com',
    @ItemList = @Items,
    @GuestList = @Guests,
    @ReservationID = @NewReservationID OUTPUT;

SELECT 'Reservation Created' AS Status, @NewReservationID AS ReservationID;

SELECT * FROM Reservation WHERE ReservationID = @NewReservationID;
SELECT * FROM Booking WHERE ReservationID = @NewReservationID;


/* ==========================================================
TEST CASE 2 – FAILURE (Exceed Capacity)
========================================================== */

DECLARE @FailID INT;
DECLARE @ItemsFail ServicePkgList;

-- Quantity intentionally exceeds capacity
INSERT INTO @ItemsFail VALUES (1, 9999, '2026-12-01', '2026-12-05');

BEGIN TRY
    EXEC usp_makeReservation
        @CustomerName = 'Fail Case',
        @Address = 'Fail Address',
        @Phone = '0000000000',
        @Email = 'fail@test.com',
        @ItemList = @ItemsFail,
        @GuestList = @Guests,
        @ReservationID = @FailID OUTPUT;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO
