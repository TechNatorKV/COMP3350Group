-- =============================================
-- 1. Create Table-Valued Parameters (TVPs)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'ServicePkgList')
    CREATE TYPE ServicePkgList AS TABLE (
        ItemID INT,         -- ID of the Advertised Service/Package
        Quantity INT,
        StartDate DATE,
        EndDate DATE
    );
GO

IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'GuestDetailList')
    CREATE TYPE GuestDetailList AS TABLE (
        GuestName VARCHAR(100),
        Address VARCHAR(255),
        ContactNumber VARCHAR(20),
        Email VARCHAR(100)
    );
GO

-- =============================================
-- 2. Create the Stored Procedure
-- =============================================
CREATE OR ALTER PROCEDURE usp_makeReservation
    @CustomerName VARCHAR(100),
    @Address VARCHAR(255),
    @Phone VARCHAR(20),
    @Email VARCHAR(100),
    @ReservedItems ServicePkgList READONLY,
    @GuestList GuestDetailList READONLY,
    @ReservationID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables for calculations
    DECLARE @TotalAmountDue DECIMAL(18, 2) = 0;
    DECLARE @DepositAmount DECIMAL(18, 2) = 0;
    DECLARE @CustomerID INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. CAPACITY VALIDATION
        -- Logic: Check if the required quantity exceeds the capacity of the underlying Facility Type
        IF EXISTS (
            SELECT 1 
            FROM @ReservedItems ri
            JOIN AdvertisedItems ai ON ri.ItemID = ai.ItemID
            JOIN ServiceItems si ON ai.ServiceItemID = si.ServiceID
            JOIN FacilityTypes ft ON si.FacilityTypeID = ft.FacilityTypeID
            WHERE ri.Quantity > ft.Capacity -- Simple capacity check logic
        )
        BEGIN
            RAISERROR('Reservation failed: One or more requested items exceed the resort capacity.', 16, 1);
        END

        -- 2. CUSTOMER MANAGEMENT
        -- Check if customer exists or create new
        SELECT @CustomerID = CustomerID FROM Customers WHERE Email = @Email;
        IF @CustomerID IS NULL
        BEGIN
            INSERT INTO Customers (CustomerName, Address, Phone, Email)
            VALUES (@CustomerName, @Address, @Phone, @Email);
            SET @CustomerID = SCOPE_IDENTITY();
        END

        -- 3. CALCULATE TOTALS
        -- Get the advertised price for each item multiplied by quantity
        SELECT @TotalAmountDue = SUM(ai.AdvertisedPrice * ri.Quantity)
        FROM @ReservedItems ri
        JOIN AdvertisedItems ai ON ri.ItemID = ai.ItemID;

        -- Business Rule: Deposit is 25% of total amount due
        SET @DepositAmount = @TotalAmountDue * 0.25;

        -- 4. INSERT RESERVATION HEADER
        INSERT INTO Reservations (CustomerID, TotalAmount, DepositDue, Status, ReservationDate)
        VALUES (@CustomerID, @TotalAmountDue, @DepositAmount, 'Confirmed', GETDATE());
        
        SET @ReservationID = SCOPE_IDENTITY();

        -- 5. SAVE RESERVED ITEMS (BOOKINGS)
        INSERT INTO ReservationItems (ReservationID, ItemID, Quantity, StartDate, EndDate)
        SELECT @ReservationID, ItemID, Quantity, StartDate, EndDate 
        FROM @ReservedItems;

        -- 6. SAVE GUEST LIST
        INSERT INTO ReservationGuests (ReservationID, GuestName, GuestAddress, ContactNumber, GuestEmail)
        SELECT @ReservationID, GuestName, Address, ContactNumber, Email 
        FROM @GuestList;

        COMMIT TRANSACTION;
        
        PRINT 'SUCCESS: Reservation ' + CAST(@ReservationID AS VARCHAR(10)) + ' created.';
        PRINT 'Total Amount: $' + CAST(@TotalAmountDue AS VARCHAR(20));
        PRINT 'Deposit Due (25%): $' + CAST(@DepositAmount AS VARCHAR(20));

    END TRY
    BEGIN CATCH
        -- Ensure the entire reservation is cancelled if any error occurs
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
