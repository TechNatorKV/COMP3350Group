USE HolidayFunDB;
GO

DECLARE @OfferList OfferReservationType;

INSERT INTO @OfferList VALUES (1, 2, '2026-04-01', '2026-04-05');

DECLARE @ReservationID INT;

EXEC usp_makeReservation
    @customerName = 'John Smith',
    @customerAddress = '123 Sydney Street',
    @customerPhone = '0400123456',
    @customerEmail = 'johnsmith@email.com',
    @OfferList = @OfferList,
    @ReservationID = @ReservationID OUTPUT;

PRINT 'Created Reservation ID:';
PRINT @ReservationID;
