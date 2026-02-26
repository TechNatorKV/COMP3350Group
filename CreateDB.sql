/*
=============================================================
HolidayFunDB – Database Implementation Script
COMP3350 – Advanced Database
Section 3 – Database Implementation
=============================================================
*/

-- ==========================================================
-- DATABASE CREATION
-- ==========================================================
CREATE DATABASE HolidayFunDB;
GO

USE HolidayFunDB;
GO

/* ==========================================================
   1. CORE ENTITY TABLES
========================================================== */

-- ----------------------------------------------------------
-- RESORT
-- ----------------------------------------------------------
CREATE TABLE Resort (
    ResortID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Address NVARCHAR(200) NOT NULL,
    Country NVARCHAR(50) NOT NULL,
    Phone NVARCHAR(20),
    Email NVARCHAR(100),
    Description NVARCHAR(500)
);

-- ----------------------------------------------------------
-- FACILITY TYPE
-- ----------------------------------------------------------
CREATE TABLE FacilityType (
    FacilityTypeID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(300),
    Capacity INT NOT NULL CHECK (Capacity > 0)
);

-- ----------------------------------------------------------
-- FACILITY
-- ----------------------------------------------------------
CREATE TABLE Facility (
    FacilityID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(300),
    Status NVARCHAR(20) CHECK (Status IN ('Available','Maintenance','Closed')),
    FacilityTypeID INT NOT NULL,
    ResortID INT NOT NULL,

    CONSTRAINT FK_Facility_Type FOREIGN KEY (FacilityTypeID)
        REFERENCES FacilityType(FacilityTypeID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT FK_Facility_Resort FOREIGN KEY (ResortID)
        REFERENCES Resort(ResortID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ----------------------------------------------------------
-- SERVICE CATEGORY
-- ----------------------------------------------------------
CREATE TABLE ServiceCategory (
    CategoryID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(300),
    TypeOfService NVARCHAR(100)
);

-- ----------------------------------------------------------
-- SERVICE ITEM
-- ----------------------------------------------------------
CREATE TABLE ServiceItem (
    ServiceID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(300),
    Restrictions NVARCHAR(300),
    Status NVARCHAR(20) CHECK (Status IN ('Available','Unavailable')),
    AvailableTimes NVARCHAR(200),
    BaseCost DECIMAL(10,2) CHECK (BaseCost >= 0),
    BaseCurrency NVARCHAR(10),
    Capacity INT CHECK (Capacity > 0),
    CategoryID INT NOT NULL,

    CONSTRAINT FK_Service_Category FOREIGN KEY (CategoryID)
        REFERENCES ServiceCategory(CategoryID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ----------------------------------------------------------
-- EMPLOYEE
-- ----------------------------------------------------------
CREATE TABLE Employee (
    EmployeeID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Role NVARCHAR(50),
    Email NVARCHAR(100)
);

-- ----------------------------------------------------------
-- ADVERTISED OFFER
-- ----------------------------------------------------------
CREATE TABLE AdvertisedOffer (
    OfferID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    AdvertisedPrice DECIMAL(10,2) CHECK (AdvertisedPrice >= 0),
    AdvertisedCurrency NVARCHAR(10),
    StartDate DATE,
    EndDate DATE,
    Inclusions NVARCHAR(500),
    Exclusions NVARCHAR(500),
    Status NVARCHAR(20),
    GracePeriod INT CHECK (GracePeriod >= 0)
);

-- ----------------------------------------------------------
-- CUSTOMER
-- ----------------------------------------------------------
CREATE TABLE Customer (
    CustomerID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Address NVARCHAR(200),
    Phone NVARCHAR(20),
    Email NVARCHAR(100)
);

-- ----------------------------------------------------------
-- GUEST
-- ----------------------------------------------------------
CREATE TABLE Guest (
    GuestID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Address NVARCHAR(200),
    Phone NVARCHAR(20),
    Email NVARCHAR(100)
);

-- ----------------------------------------------------------
-- RESERVATION
-- ----------------------------------------------------------
CREATE TABLE Reservation (
    ReservationID INT IDENTITY PRIMARY KEY,
    ReservationDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2),
    DepositAmount DECIMAL(10,2),
    Status NVARCHAR(20)
);

-- ----------------------------------------------------------
-- BOOKING
-- ----------------------------------------------------------
CREATE TABLE Booking (
    BookingID INT IDENTITY PRIMARY KEY,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    Quantity INT CHECK (Quantity > 0),
    ReservationID INT NOT NULL,
    OfferID INT NOT NULL,

    CONSTRAINT FK_Booking_Reservation FOREIGN KEY (ReservationID)
        REFERENCES Reservation(ReservationID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT FK_Booking_Offer FOREIGN KEY (OfferID)
        REFERENCES AdvertisedOffer(OfferID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ----------------------------------------------------------
-- PAYMENT
-- ----------------------------------------------------------
CREATE TABLE Payment (
    PaymentID INT IDENTITY PRIMARY KEY,
    Amount DECIMAL(10,2),
    PaymentDate DATETIME DEFAULT GETDATE(),
    PaymentMethod NVARCHAR(50),
    Status NVARCHAR(50)
);

-- ----------------------------------------------------------
-- CHARGE
-- ----------------------------------------------------------
CREATE TABLE Charge (
    ChargeID INT IDENTITY PRIMARY KEY,
    Amount DECIMAL(10,2),
    ChargeDate DATETIME DEFAULT GETDATE(),
    Description NVARCHAR(300),
    ChargeType NVARCHAR(50)
);

-- ----------------------------------------------------------
-- DISCOUNT
-- ----------------------------------------------------------
CREATE TABLE Discount (
    DiscountID INT IDENTITY PRIMARY KEY,
    DiscountAmount DECIMAL(10,2),
    Reason NVARCHAR(300)
);

/* ==========================================================
   2. ASSOCIATIVE TABLES (M:N Relationships)
========================================================== */

-- ServiceItemFacility
CREATE TABLE ServiceItemFacility (
    ServiceID INT NOT NULL,
    FacilityID INT NOT NULL,
    PRIMARY KEY (ServiceID, FacilityID),

    FOREIGN KEY (ServiceID)
        REFERENCES ServiceItem(ServiceID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (FacilityID)
        REFERENCES Facility(FacilityID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- AdvertisedOfferServiceItem
CREATE TABLE AdvertisedOfferServiceItem (
    OfferID INT NOT NULL,
    ServiceID INT NOT NULL,
    PRIMARY KEY (OfferID, ServiceID),

    FOREIGN KEY (OfferID)
        REFERENCES AdvertisedOffer(OfferID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (ServiceID)
        REFERENCES ServiceItem(ServiceID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- Authorises
CREATE TABLE Authorises (
    EmployeeID INT NOT NULL,
    OfferID INT NOT NULL,
    PRIMARY KEY (EmployeeID, OfferID),

    FOREIGN KEY (EmployeeID)
        REFERENCES Employee(EmployeeID)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,

    FOREIGN KEY (OfferID)
        REFERENCES AdvertisedOffer(OfferID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- CustomerReservation
CREATE TABLE CustomerReservation (
    CustomerID INT NOT NULL,
    ReservationID INT NOT NULL,
    PRIMARY KEY (CustomerID, ReservationID),

    FOREIGN KEY (CustomerID)
        REFERENCES Customer(CustomerID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (ReservationID)
        REFERENCES Reservation(ReservationID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- BookingGuest
CREATE TABLE BookingGuest (
    BookingID INT NOT NULL,
    GuestID INT NOT NULL,
    PRIMARY KEY (BookingID, GuestID),

    FOREIGN KEY (BookingID)
        REFERENCES Booking(BookingID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (GuestID)
        REFERENCES Guest(GuestID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- BookingFacility
CREATE TABLE BookingFacility (
    BookingFacilityID INT IDENTITY PRIMARY KEY,
    BookingID INT NOT NULL,
    FacilityID INT NOT NULL,
    StartDateTime DATETIME,
    EndDateTime DATETIME,

    FOREIGN KEY (BookingID)
        REFERENCES Booking(BookingID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (FacilityID)
        REFERENCES Facility(FacilityID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ReservationPayment
CREATE TABLE ReservationPayment (
    ReservationID INT NOT NULL,
    PaymentID INT NOT NULL,
    PRIMARY KEY (ReservationID, PaymentID),

    FOREIGN KEY (ReservationID)
        REFERENCES Reservation(ReservationID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (PaymentID)
        REFERENCES Payment(PaymentID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- BookingCharge
CREATE TABLE BookingCharge (
    BookingID INT NOT NULL,
    ChargeID INT NOT NULL,
    PRIMARY KEY (BookingID, ChargeID),

    FOREIGN KEY (BookingID)
        REFERENCES Booking(BookingID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (ChargeID)
        REFERENCES Charge(ChargeID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ReservationDiscount
CREATE TABLE ReservationDiscount (
    ReservationID INT NOT NULL,
    DiscountID INT NOT NULL,
    EmployeeID INT NOT NULL,
    PRIMARY KEY (ReservationID, DiscountID),

    FOREIGN KEY (ReservationID)
        REFERENCES Reservation(ReservationID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (DiscountID)
        REFERENCES Discount(DiscountID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (EmployeeID)
        REFERENCES Employee(EmployeeID)
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);
