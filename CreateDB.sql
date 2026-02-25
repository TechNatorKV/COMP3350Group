/*
=============================================================
HolidayFunDB – Database Implementation Script
COMP3350 – Advanced Database
Section 3 – Database Implementation

Assumptions:
1. Deposit is 25% of total amount due (as per Section 4 requirement).
2. A package is treated as an AdvertisedServicePackage.
3. Individual services are also advertised via AdvertisedServicePackage.
4. Discounts above 25% require Head Office authorization.
5. Facility booking is stored separately to track time allocations.
=============================================================
*/

-- ==========================================================
-- DATABASE CREATION
-- ==========================================================
CREATE DATABASE HolidayFunDB;
GO

USE HolidayFunDB;
GO

-- ==========================================================
-- EMPLOYEE TABLE
-- ==========================================================
CREATE TABLE Employee (
    EmployeeID INT IDENTITY PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Role NVARCHAR(50) NOT NULL CHECK (Role IN ('Manager','FrontOffice','HeadOffice')),
    Email NVARCHAR(100) UNIQUE
);

-- ==========================================================
-- RESORT
-- ==========================================================
CREATE TABLE Resort (
    ResortID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Address NVARCHAR(200) NOT NULL,
    Country NVARCHAR(50) NOT NULL,
    Phone NVARCHAR(20),
    Email NVARCHAR(100),
    Description NVARCHAR(500)
);

-- ==========================================================
-- FACILITY TYPES
-- ==========================================================
CREATE TABLE FacilityType (
    FacilityTypeID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(200),
    Capacity INT NOT NULL CHECK (Capacity > 0)
);

-- ==========================================================
-- FACILITIES
-- ==========================================================
CREATE TABLE Facility (
    FacilityID INT IDENTITY PRIMARY KEY,
    ResortID INT NOT NULL,
    FacilityTypeID INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Status NVARCHAR(20) DEFAULT 'Available'
        CHECK (Status IN ('Available','Maintenance','Closed')),
    CONSTRAINT FK_Facility_Resort FOREIGN KEY (ResortID)
        REFERENCES Resort(ResortID),
    CONSTRAINT FK_Facility_Type FOREIGN KEY (FacilityTypeID)
        REFERENCES FacilityType(FacilityTypeID)
);

-- ==========================================================
-- SERVICE CATEGORY
-- ==========================================================
CREATE TABLE ServiceCategory (
    ServiceCategoryID INT IDENTITY PRIMARY KEY,
    Code NVARCHAR(10) NOT NULL UNIQUE,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(200),
    Type NVARCHAR(50)
);

-- ==========================================================
-- SERVICE ITEM
-- ==========================================================
CREATE TABLE ServiceItem (
    ServiceID INT IDENTITY PRIMARY KEY,
    ServiceCategoryID INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(300),
    Status NVARCHAR(20) DEFAULT 'Available'
        CHECK (Status IN ('Available','Unavailable')),
    BaseCost DECIMAL(10,2) NOT NULL CHECK (BaseCost >= 0),
    BaseCurrency NVARCHAR(10) NOT NULL,
    Capacity INT CHECK (Capacity > 0),
    CONSTRAINT FK_Service_Category FOREIGN KEY (ServiceCategoryID)
        REFERENCES ServiceCategory(ServiceCategoryID)
);

-- ==========================================================
-- ADVERTISED SERVICE / PACKAGE
-- ==========================================================
CREATE TABLE AdvertisedServicePackage (
    AdvertisedID INT IDENTITY PRIMARY KEY,
    ResortID INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    AdvertisedPrice DECIMAL(10,2) NOT NULL CHECK (AdvertisedPrice >= 0),
    AdvertisedCurrency NVARCHAR(10) NOT NULL,
    GracePeriodDays INT NOT NULL CHECK (GracePeriodDays >= 0),
    Status NVARCHAR(20) DEFAULT 'Active'
        CHECK (Status IN ('Active','Inactive')),
    AuthorizedBy INT NOT NULL,
    CONSTRAINT FK_Advertised_Resort FOREIGN KEY (ResortID)
        REFERENCES Resort(ResortID),
    CONSTRAINT FK_Advertised_Employee FOREIGN KEY (AuthorizedBy)
        REFERENCES Employee(EmployeeID),
    CONSTRAINT CK_DateRange CHECK (EndDate >= StartDate)
);

-- ==========================================================
-- PACKAGE CONTENT (M:N)
-- ==========================================================
CREATE TABLE PackageService (
    AdvertisedID INT NOT NULL,
    ServiceID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    PRIMARY KEY (AdvertisedID, ServiceID),
    FOREIGN KEY (AdvertisedID) REFERENCES AdvertisedServicePackage(AdvertisedID),
    FOREIGN KEY (ServiceID) REFERENCES ServiceItem(ServiceID)
);

-- ==========================================================
-- CUSTOMER
-- ==========================================================
CREATE TABLE Customer (
    CustomerID INT IDENTITY PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Address NVARCHAR(200),
    Phone NVARCHAR(20),
    Email NVARCHAR(100) UNIQUE
);

-- ==========================================================
-- RESERVATION
-- ==========================================================
CREATE TABLE Reservation (
    ReservationID INT IDENTITY PRIMARY KEY,
    CustomerID INT NOT NULL,
    ReservationDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2) CHECK (TotalAmount >= 0),
    DepositAmount DECIMAL(10,2) CHECK (DepositAmount >= 0),
    Status NVARCHAR(20) DEFAULT 'Pending'
        CHECK (Status IN ('Pending','Confirmed','Cancelled','Completed')),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- ==========================================================
-- RESERVATION DETAILS
-- ==========================================================
CREATE TABLE ReservationDetail (
    ReservationDetailID INT IDENTITY PRIMARY KEY,
    ReservationID INT NOT NULL,
    AdvertisedID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID),
    FOREIGN KEY (AdvertisedID) REFERENCES AdvertisedServicePackage(AdvertisedID),
    CHECK (EndDate >= StartDate)
);

-- ==========================================================
-- FACILITY BOOKING
-- ==========================================================
CREATE TABLE FacilityBooking (
    FacilityBookingID INT IDENTITY PRIMARY KEY,
    ReservationDetailID INT NOT NULL,
    FacilityID INT NOT NULL,
    StartDateTime DATETIME NOT NULL,
    EndDateTime DATETIME NOT NULL,
    FOREIGN KEY (ReservationDetailID)
        REFERENCES ReservationDetail(ReservationDetailID),
    FOREIGN KEY (FacilityID)
        REFERENCES Facility(FacilityID),
    CHECK (EndDateTime > StartDateTime)
);

-- ==========================================================
-- CHARGES (Extra services used after check-in)
-- ==========================================================
CREATE TABLE BookingCharge (
    ChargeID INT IDENTITY PRIMARY KEY,
    ReservationID INT NOT NULL,
    ServiceID INT NOT NULL,
    ChargeAmount DECIMAL(10,2) NOT NULL CHECK (ChargeAmount >= 0),
    ChargeDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID),
    FOREIGN KEY (ServiceID) REFERENCES ServiceItem(ServiceID)
);

-- ==========================================================
-- DISCOUNT
-- ==========================================================
CREATE TABLE Discount (
    DiscountID INT IDENTITY PRIMARY KEY,
    ReservationID INT NOT NULL,
    DiscountAmount DECIMAL(10,2) NOT NULL CHECK (DiscountAmount >= 0),
    AuthorizedBy INT NOT NULL,
    FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID),
    FOREIGN KEY (AuthorizedBy) REFERENCES Employee(EmployeeID)
);

-- ==========================================================
-- PAYMENT
-- ==========================================================
CREATE TABLE Payment (
    PaymentID INT IDENTITY PRIMARY KEY,
    ReservationID INT NOT NULL,
    PaymentDate DATETIME DEFAULT GETDATE(),
    Amount DECIMAL(10,2) NOT NULL CHECK (Amount > 0),
    PaymentMethod NVARCHAR(20)
        CHECK (PaymentMethod IN ('CreditCard','DebitCard','Cash','Online')),
    FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID)
);

-- ==========================================================
-- SAMPLE DATA (Meaningful & Sufficient)
-- ==========================================================

INSERT INTO Employee (FullName, Role, Email)
VALUES
('Alice Manager','Manager','alice@holidayfun.com'),
('Bob Front','FrontOffice','bob@holidayfun.com'),
('Helen Head','HeadOffice','headoffice@holidayfun.com');

INSERT INTO Resort (Name, Address, Country, Phone, Email, Description)
VALUES
('Resort Paradise','Sydney Beach','Australia','021234567','info@rp.com','Luxury Beach Resort'),
('Mountain Escape','Melbourne Hills','Australia','039876543','info@me.com','Mountain Resort');

INSERT INTO FacilityType (Name, Description, Capacity)
VALUES
('Standard Room','Basic room',2),
('Conference Hall','Event Hall',100);

INSERT INTO Facility (ResortID, FacilityTypeID, Name)
VALUES
(1,1,'Room 101'),
(1,1,'Room 102'),
(2,2,'Hall A');

INSERT INTO ServiceCategory (Code, Name)
VALUES
('ACC','Accommodation'),
('FD','Food & Drink');

INSERT INTO ServiceItem (ServiceCategoryID, Name, BaseCost, BaseCurrency, Capacity)
VALUES
(1,'Standard Room Night',150,'AUD',2),
(2,'Buffet Breakfast',20,'AUD',50),
(2,'Dinner Meal',35,'AUD',50);

INSERT INTO AdvertisedServicePackage
(ResortID, Name, StartDate, EndDate, AdvertisedPrice,
 AdvertisedCurrency, GracePeriodDays, AuthorizedBy)
VALUES
(1,'Half Board Package','2026-01-01','2026-12-31',250,'AUD',2,1);

INSERT INTO PackageService VALUES (1,1,1);
INSERT INTO PackageService VALUES (1,2,2);

INSERT INTO Customer (FullName, Email)
VALUES
('John Smith','john@email.com'),
('Emma Brown','emma@email.com');

INSERT INTO Reservation (CustomerID, TotalAmount, DepositAmount, Status)
VALUES
(1,500,125,'Confirmed'),
(2,250,62.5,'Pending');
