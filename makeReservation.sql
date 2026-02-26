/* ============================================================
   COMP3350 – Assignment 1
   Section 4 – Stored Procedure
   Procedure: usp_makeReservation
   ============================================================ */

USE HolidayFunDB;
GO

/* ============================================================
   1. Create Table-Valued Parameter Type
   ============================================================ */

IF TYPE_ID('OfferReservationType') IS NOT NULL
    DROP TYPE OfferReservationType;
GO

CREATE TYPE OfferReservationType AS TABLE
(
    offerID INT,
    quantity INT,
    startDate DATE,
    endDate DATE
);
GO


/* ============================================================
   2. Stored Procedure: usp_makeReservation
   ============================================================ */

IF OBJECT_ID('usp_makeReservation') IS NOT NULL
    DROP PROCEDURE usp_makeReservation;
GO

CREATE PROCEDURE usp_makeReservation
(
    -- Customer Details
    @customerName VARCHAR(100),
    @customerAddress VARCHAR(200),
    @customerPhone VARCHAR(20),
    @customerEmail VARCHAR(100),

    -- Reserved Offers
    @OfferList OfferReservationType READONLY,

    -- Output
    @ReservationID INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CustomerID INT;
        DECLARE @TotalAmount DECIMAL(10,2) = 0;
        DECLARE @DepositAmount DECIMAL(10,2);

        /* ====================================================
           1. Check or Insert Customer
           ==================================================== */

        SELECT @CustomerID = customerID
        FROM Customer
        WHERE email = @customerEmail;

        IF @CustomerID IS NULL
        BEGIN
            INSERT INTO Customer (name, address, phone, email)
            VALUES (@customerName, @customerAddress, @customerPhone, @customerEmail);

            SET @CustomerID = SCOPE_IDENTITY();
        END

        /* ====================================================
           2. Validate Booking Dates
           ==================================================== */

        IF EXISTS (
            SELECT 1 FROM @OfferList
            WHERE endDate <= startDate
        )
        BEGIN
            RAISERROR('End date must be after start date.',16,1);
        END

        /* ====================================================
           3. Capacity Check
           ==================================================== */

        DECLARE @offerID INT, @quantity INT, @startDate DATE, @endDate DATE;
        DECLARE offer_cursor CURSOR FOR
        SELECT offerID, quantity, startDate, endDate
        FROM @OfferList;

        OPEN offer_cursor;
        FETCH NEXT FROM offer_cursor INTO @offerID, @quantity, @startDate, @endDate;

        WHILE @@FETCH_STATUS = 0
        BEGIN

            DECLARE @Capacity INT;

            SELECT @Capacity = MIN(si.capacity)
            FROM AdvertisedOfferServiceItem aos
            JOIN ServiceItem si ON aos.serviceID = si.serviceID
            WHERE aos.offerID = @offerID;

            DECLARE @BookedQty INT;

            SELECT @BookedQty = ISNULL(SUM(b.quantity),0)
            FROM Booking b
            WHERE b.offerID = @offerID
            AND (
                b.startDate < @endDate
                AND b.endDate > @startDate
            );

            IF (@BookedQty + @quantity) > @Capacity
            BEGIN
                RAISERROR('Capacity exceeded for one or more offers.',16,1);
            END

            FETCH NEXT FROM offer_cursor INTO @offerID, @quantity, @startDate, @endDate;
        END

        CLOSE offer_cursor;
        DEALLOCATE offer_cursor;

        /* ====================================================
           4. Insert Reservation
           ==================================================== */

        INSERT INTO Reservation (reservationDate, totalAmount, depositAmount, status, customerID)
        VALUES (GETDATE(), 0, 0, 'Pending', @CustomerID);

        SET @ReservationID = SCOPE_IDENTITY();

        /* ====================================================
           5. Insert Bookings and Calculate Total
           ==================================================== */

        DECLARE booking_cursor CURSOR FOR
        SELECT offerID, quantity, startDate, endDate
        FROM @OfferList;

        OPEN booking_cursor;
        FETCH NEXT FROM booking_cursor INTO @offerID, @quantity, @startDate, @endDate;

        WHILE @@FETCH_STATUS = 0
        BEGIN

            DECLARE @Price DECIMAL(10,2);
            DECLARE @Days INT;

            SELECT @Price = advertisedPrice
            FROM AdvertisedOffer
            WHERE offerID = @offerID
            AND GETDATE() BETWEEN startDate AND endDate;

            SET @Days = DATEDIFF(DAY, @startDate, @endDate);

            IF @Price IS NULL
            BEGIN
                RAISERROR('Offer not valid for current date.',16,1);
            END

            INSERT INTO Booking (startDate, endDate, quantity, reservationID, offerID)
            VALUES (@startDate, @endDate, @quantity, @ReservationID, @offerID);

            SET @TotalAmount = @TotalAmount + (@Price * @quantity * @Days);

            FETCH NEXT FROM booking_cursor INTO @offerID, @quantity, @startDate, @endDate;
        END

        CLOSE booking_cursor;
        DEALLOCATE booking_cursor;

        /* ====================================================
           6. Calculate Deposit (25%)
           ==================================================== */

        SET @DepositAmount = @TotalAmount * 0.25;

        UPDATE Reservation
        SET totalAmount = @TotalAmount,
            depositAmount = @DepositAmount,
            status = 'Confirmed'
        WHERE reservationID = @ReservationID;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000);
        SET @ErrorMessage = ERROR_MESSAGE();

        RAISERROR(@ErrorMessage,16,1);
    END CATCH
END
GO
