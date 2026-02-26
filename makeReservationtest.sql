/*
=============================================================
Section 4 – Database Queries & Demonstration
COMP3350 – Advanced Database
This script demonstrates data retrieval, joins,
aggregation, filtering, and business logic queries.
=============================================================
*/

USE HolidayFunDB;
GO

/* ==========================================================
4.1 View All Resorts and Their Facilities
========================================================== */
SELECT 
    R.Name AS ResortName,
    F.Name AS FacilityName,
    FT.Name AS FacilityType,
    F.Status
FROM Resort R
JOIN Facility F ON R.ResortID = F.ResortID
JOIN FacilityType FT ON F.FacilityTypeID = FT.FacilityTypeID
ORDER BY R.Name;

GO

/* ==========================================================
4.2 List All Services Included in an Advertised Offer
========================================================== */
SELECT 
    AO.Name AS OfferName,
    SI.Name AS ServiceName,
    SI.BaseCost,
    SI.BaseCurrency
FROM AdvertisedOffer AO
JOIN AdvertisedOfferServiceItem AOSI 
    ON AO.OfferID = AOSI.OfferID
JOIN ServiceItem SI 
    ON AOSI.ServiceID = SI.ServiceID
ORDER BY AO.Name;

GO

/* ==========================================================
4.3 Show Reservations with Customer Details
========================================================== */
SELECT 
    C.Name AS CustomerName,
    R.ReservationID,
    R.ReservationDate,
    R.TotalAmount,
    R.Status
FROM Customer C
JOIN CustomerReservation CR 
    ON C.CustomerID = CR.CustomerID
JOIN Reservation R 
    ON CR.ReservationID = R.ReservationID
ORDER BY R.ReservationDate DESC;

GO

/* ==========================================================
4.4 Total Revenue from Completed Reservations
========================================================== */
SELECT 
    SUM(TotalAmount) AS TotalRevenue
FROM Reservation
WHERE Status = 'Completed';

GO

/* ==========================================================
4.5 Total Additional Charges Per Booking
========================================================== */
SELECT 
    B.BookingID,
    SUM(C.Amount) AS TotalCharges
FROM Booking B
JOIN BookingCharge BC 
    ON B.BookingID = BC.BookingID
JOIN Charge C 
    ON BC.ChargeID = C.ChargeID
GROUP BY B.BookingID;

GO

/* ==========================================================
4.6 Guests Assigned to Each Booking
========================================================== */
SELECT 
    B.BookingID,
    G.Name AS GuestName
FROM Booking B
JOIN BookingGuest BG 
    ON B.BookingID = BG.BookingID
JOIN Guest G 
    ON BG.GuestID = G.GuestID
ORDER BY B.BookingID;

GO

/* ==========================================================
4.7 Employees Who Authorised Offers
========================================================== */
SELECT 
    E.Name AS EmployeeName,
    AO.Name AS OfferName
FROM Employee E
JOIN Authorises A 
    ON E.EmployeeID = A.EmployeeID
JOIN AdvertisedOffer AO 
    ON A.OfferID = AO.OfferID;

GO

/* ==========================================================
4.8 Facilities Booked Within 2026
========================================================== */
SELECT 
    F.Name AS FacilityName,
    BF.StartDateTime,
    BF.EndDateTime
FROM BookingFacility BF
JOIN Facility F 
    ON BF.FacilityID = F.FacilityID
WHERE BF.StartDateTime BETWEEN '2026-01-01' AND '2026-12-31';

GO

/* ==========================================================
4.9 Offers Expiring Within 30 Days
========================================================== */
SELECT 
    Name,
    EndDate
FROM AdvertisedOffer
WHERE EndDate <= DATEADD(DAY, 30, GETDATE());

GO

/* ==========================================================
4.10 Total Payments Per Reservation
========================================================== */
SELECT 
    R.ReservationID,
    SUM(P.Amount) AS TotalPaid
FROM Reservation R
JOIN ReservationPayment RP 
    ON R.ReservationID = RP.ReservationID
JOIN Payment P 
    ON RP.PaymentID = P.PaymentID
GROUP BY R.ReservationID;

GO
