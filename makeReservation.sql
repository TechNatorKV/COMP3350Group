-- ==========================================================
-- Section 4: Stored Procedures
-- Procedure name: usp_makeReservation
-- ==========================================================
USE HolidayFunDB;
GO

-- First, define the Table-Valued Parameters required by the prompt
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'ServicePkgList')
    CREATE TYPE ServicePkgList AS TABLE (
        AdvertisedID INT,
        Quantity INT,
        StartDate DATE,
        EndDate DATE
    );
GO

IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'GuestListType')
    CREATE TYPE GuestListType AS TABLE (
        FullName NVARCHAR(100),
        Address NVARCHAR(200),
        Phone NVARCHAR(20),
        Email NVARCHAR(100)
    );
GO

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
    
    DECLARE @TotalAmount DECIMAL(10,2) = 0;
    DECLARE @DepositAmount DECIMAL(10,2) = 0;
    DECLARE @CustomerID INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Capacity Check Logic
        -- Ensure reservation does not exceed available capacity (Section 4 Functional Requirement)
        IF EXISTS (
            SELECT 1 
            FROM @ItemList il
            JOIN AdvertisedServicePackage asp ON il.AdvertisedID = asp.AdvertisedID
            JOIN PackageService ps ON asp.AdvertisedID = ps.AdvertisedID
            JOIN ServiceItem si ON ps.ServiceID = si.ServiceID
            WHERE il.Quantity > si.Capacity
        )
        BEGIN
            -- Raised error as per Section 4 requirement
            RAISERROR('Insufficient capacity available for one or more services. Reservation cancelled.', 16, 1);
        END

        -- 2. Customer Management
        -- Check if customer exists, otherwise insert
        SELECT @CustomerID = CustomerID FROM Customer WHERE Email = @Email;
        IF @CustomerID IS NULL
        BEGIN
            INSERT INTO Customer (FullName, Address, Phone, Email)
            VALUES (@CustomerName, @Address, @Phone, @Email);
            SET @CustomerID = SCOPE_IDENTITY();
        END

        -- 3. Calculate Amounts
        -- Calculate Total and Deposit (25% as per Section 4 requirement)
        SELECT @TotalAmount = SUM(asp.AdvertisedPrice * il.Quantity)
        FROM @ItemList il
        JOIN AdvertisedServicePackage asp ON il.AdvertisedID = asp.AdvertisedID;

        SET @DepositAmount = @TotalAmount * 0.25;

        -- 4. Save Valid Reservation
        INSERT INTO Reservation (CustomerID, TotalAmount, DepositAmount, Status, ReservationDate)
        VALUES (@CustomerID, @TotalAmount, @DepositAmount, 'Confirmed', GETDATE());
        
        SET @ReservationID = SCOPE_IDENTITY();

        -- 5. Save Bookings of Facilities
        INSERT INTO ReservationDetail (ReservationID, AdvertisedID, Quantity, StartDate, EndDate)
        SELECT @ReservationID, AdvertisedID, Quantity, StartDate, EndDate 
        FROM @ItemList;

        -- Link to a facility (Simple assignment logic for demonstration)
        INSERT INTO FacilityBooking (ReservationDetailID, FacilityID, StartDateTime, EndDateTime)
        SELECT 
            rd.ReservationDetailID, 
            (SELECT TOP 1 FacilityID FROM Facility WHERE Status = 'Available'), 
            CAST(rd.StartDate AS DATETIME), 
            CAST(rd.EndDate AS DATETIME)
        FROM ReservationDetail rd
        WHERE rd.ReservationID = @ReservationID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW; -- Re-raise the error to the calling test script
    END CATCH
END;
GO
