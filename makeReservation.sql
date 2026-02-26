USE HolidayFunDB;
GO

/*
=============================================================
Procedure: usp_makeReservation
Function: Creates a reservation with validation.
- Validates service capacity
- Calculates total and 25% deposit
- Creates reservation + booking
- Assigns facility
- Adds guests
- Rolls back fully if error occurs
=============================================================
*/

-- ==========================================================
-- TABLE TYPES
-- ==========================================================

IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'ServicePkgList')
CREATE TYPE ServicePkgList AS TABLE (
    OfferID INT,
    Quantity INT,
    StartDate DATE,
    EndDate DATE
);
GO

IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'GuestListType')
CREATE TYPE GuestListType AS TABLE (
    Name NVARCHAR(100),
    Address NVARCHAR(200),
    Phone NVARCHAR(20),
    Email NVARCHAR(100)
);
GO

-- ==========================================================
-- STORED PROCEDURE
-- ==========================================================

CREATE OR ALTER PROCEDURE usp_makeReservation
    @CustomerName NVARCHAR(100),
    @Address NVARCHAR(200),
    @Phone NVARCHAR(20),
    @Email NVARCHAR(100),
    @ItemList ServicePkgList READONLY,
    @GuestList GuestListType READONLY,
    @ReservationID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CustomerID INT;
    DECLARE @TotalAmount DECIMAL(10,2);
    DECLARE @DepositAmount DECIMAL(10,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        /* =====================================================
           1. VALIDATE CAPACITY
           Ensure quantity does not exceed facility capacity
        ===================================================== */

        IF EXISTS (
            SELECT 1
            FROM @ItemList I
            JOIN AdvertisedOffer AO ON I.OfferID = AO.OfferID
            JOIN AdvertisedOfferServiceItem AOSI ON AO.OfferID = AOSI.OfferID
            JOIN ServiceItem SI ON AOSI.ServiceID = SI.ServiceID
            WHERE I.Quantity > SI.Capacity
        )
        BEGIN
            THROW 50001, 
            'Reservation exceeds available capacity for one or more services. Reservation cancelled.',
            1;
        END

        /* =====================================================
           2. CREATE OR RETRIEVE CUSTOMER
        ===================================================== */

        SELECT @CustomerID = CustomerID 
        FROM Customer 
        WHERE Email = @Email;

        IF @CustomerID IS NULL
        BEGIN
            INSERT INTO Customer (Name, Address, Phone, Email)
            VALUES (@CustomerName, @Address, @Phone, @Email);

            SET @CustomerID = SCOPE_IDENTITY();
        END

        /* =====================================================
           3. CALCULATE TOTAL & DEPOSIT (25%)
        ===================================================== */

        SELECT @TotalAmount = SUM(AO.AdvertisedPrice * I.Quantity)
        FROM @ItemList I
        JOIN AdvertisedOffer AO ON I.OfferID = AO.OfferID;

        SET @DepositAmount = @TotalAmount * 0.25;

        /* =====================================================
           4. CREATE RESERVATION
        ===================================================== */

        INSERT INTO Reservation (ReservationDate, TotalAmount, DepositAmount, Status)
        VALUES (GETDATE(), @TotalAmount, @DepositAmount, 'Confirmed');

        SET @ReservationID = SCOPE_IDENTITY();

        INSERT INTO CustomerReservation (CustomerID, ReservationID)
        VALUES (@CustomerID, @ReservationID);

        /* =====================================================
           5. CREATE BOOKINGS
        ===================================================== */

        DECLARE @BookingID INT;

        DECLARE item_cursor CURSOR FOR
        SELECT OfferID, Quantity, StartDate, EndDate
        FROM @ItemList;

        DECLARE @OfferID INT, @Qty INT, @Start DATE, @End DATE;

        OPEN item_cursor;
        FETCH NEXT FROM item_cursor INTO @OfferID, @Qty, @Start, @End;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO Booking (StartDate, EndDate, Quantity, ReservationID, OfferID)
            VALUES (@Start, @End, @Qty, @ReservationID, @OfferID);

            SET @BookingID = SCOPE_IDENTITY();

            /* Assign first available facility */
            INSERT INTO BookingFacility (BookingID, FacilityID, StartDateTime, EndDateTime)
            SELECT TOP 1 
                @BookingID,
                F.FacilityID,
                CAST(@Start AS DATETIME),
                CAST(@End AS DATETIME)
            FROM Facility F
            WHERE F.Status = 'Available';

            /* Add guests */
            INSERT INTO Guest (Name, Address, Phone, Email)
            SELECT Name, Address, Phone, Email
            FROM @GuestList;

            INSERT INTO BookingGuest (BookingID, GuestID)
            SELECT @BookingID, G.GuestID
            FROM Guest G
            WHERE G.Email IN (SELECT Email FROM @GuestList);

            FETCH NEXT FROM item_cursor INTO @OfferID, @Qty, @Start, @End;
        END

        CLOSE item_cursor;
        DEALLOCATE item_cursor;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO
