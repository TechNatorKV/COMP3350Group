/* ============================================================
   COMP3350 – Advanced Database
   Assignment 1 – Section 3
   HolidayFun Central Database
   ============================================================ */

-- ============================================================
-- 1. Create Database
-- ============================================================

IF DB_ID('HolidayFunDB') IS NOT NULL
    DROP DATABASE HolidayFunDB;
GO

CREATE DATABASE HolidayFunDB;
GO

USE HolidayFunDB;
GO


/* ============================================================
   2. Core Resort Structure
   ============================================================ */

CREATE TABLE Resort (
    resortID INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200) NOT NULL,
    country VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(500)
);

CREATE TABLE FacilityType (
    facilityTypeID INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(300),
    capacity INT NOT NULL CHECK (capacity > 0)
);

CREATE TABLE Facility (
    facilityID INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(300),
    status VARCHAR(20) NOT NULL CHECK (status IN ('Available','Maintenance','Closed')),
    facilityTypeID INT NOT NULL,
    resortID INT NOT NULL,
    CONSTRAINT FK_Facility_FacilityType
        FOREIGN KEY (facilityTypeID)
        REFERENCES FacilityType(facilityTypeID)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT FK_Facility_Resort
        FOREIGN KEY (resortID)
        REFERENCES Resort(resortID)
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);


/* ============================================================
   3. Services
   ============================================================ */

CREATE TABLE ServiceCategory (
    categoryID INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(300),
    typeOfService VARCHAR(100) NOT NULL
);

CREATE TABLE ServiceItem (
    serviceID INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    restrictions VARCHAR(300),
    status VARCHAR(20) NOT NULL CHECK (status IN ('Active','Inactive')),
    availableTimes VARCHAR(100),
    baseCost DECIMAL(10,2) NOT NULL CHECK (baseCost > 0),
    baseCurrency VARCHAR(10) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    categoryID INT NOT NULL,
    CONSTRAINT FK_ServiceItem_Category
        FOREIGN KEY (categoryID)
        REFERENCES ServiceCategory(categoryID)
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);

-- M:N between ServiceItem and Facility
CREATE TABLE ServiceItemFacility (
    serviceID INT NOT NULL,
    facilityID INT NOT NULL,
    PRIMARY KEY (serviceID, facilityID),
    FOREIGN KEY (serviceID)
        REFERENCES ServiceItem(serviceID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (facilityID)
        REFERENCES Facility(facilityID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


/* ============================================================
   4. Employees & Offers
   ============================================================ */

CREATE TABLE Employee (
    employeeID INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE AdvertisedOffer (
    offerID INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description VARCHAR(500),
    advertisedPrice DECIMAL(10,2) NOT NULL CHECK (advertisedPrice > 0),
    advertisedCurrency VARCHAR(10) NOT NULL,
    startDate DATE NOT NULL,
    endDate DATE NOT NULL,
    inclusions VARCHAR(500),
    exclusions VARCHAR(500),
    status VARCHAR(20) NOT NULL CHECK (status IN ('Active','Inactive','Seasonal')),
    gracePeriod INT NOT NULL CHECK (gracePeriod >= 0),
    employeeID INT NOT NULL,
    CONSTRAINT CK_Offer_Dates CHECK (endDate > startDate),
    FOREIGN KEY (employeeID)
        REFERENCES Employee(employeeID)
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);

-- M:N between Offer and ServiceItem
CREATE TABLE AdvertisedOfferServiceItem (
    offerID INT NOT NULL,
    serviceID INT NOT NULL,
    PRIMARY KEY (offerID, serviceID),
    FOREIGN KEY (offerID)
        REFERENCES AdvertisedOffer(offerID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (serviceID)
        REFERENCES ServiceItem(serviceID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


/* ============================================================
   5. Customers & Reservations
   ============================================================ */

CREATE TABLE Customer (
    customerID INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Reservation (
    reservationID INT IDENTITY(1,1) PRIMARY KEY,
    reservationDate DATE NOT NULL DEFAULT GETDATE(),
    totalAmount DECIMAL(10,2) NOT NULL CHECK (totalAmount >= 0),
    depositAmount DECIMAL(10,2) NOT NULL CHECK (depositAmount >= 0),
    status VARCHAR(20) NOT NULL CHECK (status IN ('Pending','Confirmed','Cancelled','Completed')),
    customerID INT NOT NULL,
    FOREIGN KEY (customerID)
        REFERENCES Customer(customerID)
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);

CREATE TABLE Booking (
    bookingID INT IDENTITY(1,1) PRIMARY KEY,
    startDate DATE NOT NULL,
    endDate DATE NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    reservationID INT NOT NULL,
    offerID INT NOT NULL,
    CONSTRAINT CK_Booking_Dates CHECK (endDate > startDate),
    FOREIGN KEY (reservationID)
        REFERENCES Reservation(reservationID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (offerID)
        REFERENCES AdvertisedOffer(offerID)
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);

CREATE TABLE Guest (
    guestID INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    phone VARCHAR(20),
    email VARCHAR(100)
);

CREATE TABLE BookingGuest (
    bookingID INT NOT NULL,
    guestID INT NOT NULL,
    PRIMARY KEY (bookingID, guestID),
    FOREIGN KEY (bookingID)
        REFERENCES Booking(bookingID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (guestID)
        REFERENCES Guest(guestID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


/* ============================================================
   6. Facility Reservation Tracking
   ============================================================ */

CREATE TABLE BookingFacility (
    bookingFacilityID INT IDENTITY(1,1) PRIMARY KEY,
    bookingID INT NOT NULL,
    facilityID INT NOT NULL,
    startDateTime DATETIME2 NOT NULL,
    endDateTime DATETIME2 NOT NULL,
    CONSTRAINT CK_Facility_Time CHECK (endDateTime > startDateTime),
    FOREIGN KEY (bookingID)
        REFERENCES Booking(bookingID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (facilityID)
        REFERENCES Facility(facilityID)
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);


/* ============================================================
   7. Charges, Payments & Discounts
   ============================================================ */

CREATE TABLE Charge (
    chargeID INT IDENTITY(1,1) PRIMARY KEY,
    bookingID INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    chargeDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    description VARCHAR(300),
    chargeType VARCHAR(50),
    FOREIGN KEY (bookingID)
        REFERENCES Booking(bookingID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE Payment (
    paymentID INT IDENTITY(1,1) PRIMARY KEY,
    reservationID INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    paymentDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    paymentMethod VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Paid','Pending','Failed')),
    FOREIGN KEY (reservationID)
        REFERENCES Reservation(reservationID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE Discount (
    discountID INT IDENTITY(1,1) PRIMARY KEY,
    reservationID INT NOT NULL,
    discountAmount DECIMAL(10,2) NOT NULL CHECK (discountAmount >= 0),
    reason VARCHAR(300),
    employeeID INT NOT NULL,
    FOREIGN KEY (reservationID)
        REFERENCES Reservation(reservationID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (employeeID)
        REFERENCES Employee(employeeID)
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);
