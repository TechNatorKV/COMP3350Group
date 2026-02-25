-- CreateDB.sql
-- Database for HolidayFun Resort Management
-- Section 3: Database Implementation

-- 1. Create database
CREATE DATABASE HolidayFunDB;
GO

USE HolidayFunDB;
GO

-- 2. Create tables

-- Table: Resort
CREATE TABLE Resort (
    ResortID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Address NVARCHAR(200) NOT NULL,
    Country NVARCHAR(50) NOT NULL,
    PhoneNumber NVARCHAR(20),
    Email NVARCHAR(100),
    Description NVARCHAR(500)
);

-- Table: FacilityType
CREATE TABLE FacilityType (
    FacilityTypeID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(200),
    Capacity INT NOT NULL CHECK (Capacity > 0)
);

-- Table: Facility
CREATE TABLE Facility (
    FacilityID INT IDENTITY(1,1) PRIMARY KEY,
    ResortID INT NOT NULL,
    FacilityTypeID INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    Status NVARCHAR(20) CHECK (Status IN ('Available', 'Maintenance', 'Closed')) DEFAULT 'Available',
    CONSTRAINT FK_Facility_Resort FOREIGN KEY (ResortID) REFERENCES Resort(ResortID),
    CONSTRAINT FK_Facility_Type FOREIGN KEY (FacilityTypeID) REFERENCES FacilityType(FacilityTypeID)
);

-- Table: ServiceCategory
CREATE TABLE ServiceCategory (
    ServiceCategoryID INT IDENTITY(1,1) PRIMARY KEY,
    Code NVARCHAR(10) NOT NULL UNIQUE,
    Name NVARCHAR(50) NOT NULL,
    Description NVARCHAR(200),
    Type NVARCHAR(50)
);

-- Table: ServiceItem
CREATE TABLE ServiceItem (
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,
    ServiceCategoryID INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    Restrictions NVARCHAR(200),
    Status NVARCHAR(20) CHECK (Status IN ('Available','Unavailable')) DEFAULT 'Available',
    AvailableTimes NVARCHAR(100),
    BaseCost DECIMAL(10,2) NOT NULL CHECK (BaseCost >= 0),
    BaseCurrency NVARCHAR(10) NOT NULL,
    Capacity INT CHECK (Capacity > 0),
    CONSTRAINT FK_ServiceItem_Category FOREIGN KEY (ServiceCategoryID) REFERENCES ServiceCategory(ServiceCategoryID)
);

-- Table: AdvertisedServicePackage
CREATE TABLE AdvertisedServicePackage (
    AdvertisedID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    AdvertisedPrice DECIMAL(10,2) NOT NULL CHECK (AdvertisedPrice >= 0),
    AdvertisedCurrency NVARCHAR(10) NOT NULL,
    Inclusions NVARCHAR(500),
    Exclusions NVARCHAR(500),
    Status NVARCHAR(20) CHECK (Status IN ('Active','Inactive')) DEFAULT 'Active',
    GracePeriodDays INT CHECK (GracePeriodDays >= 0),
    AuthorizingEmployee NVARCHAR(100)
);

-- Table: AdvertisedServiceItems (link between package and service items)
CREATE TABLE AdvertisedServiceItems (
    AdvertisedID INT NOT NULL,
    ServiceID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    PRIMARY KEY (AdvertisedID, ServiceID),
    CONSTRAINT FK_AdvertisedService FOREIGN KEY (AdvertisedID) REFERENCES AdvertisedServicePackage(AdvertisedID),
    CONSTRAINT FK_AdvertisedItem_Service FOREIGN KEY (ServiceID) REFERENCES ServiceItem(ServiceID)
);

-- Table: Customer
CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Address NVARCHAR(200),
    PhoneNumber NVARCHAR(20),
    Email NVARCHAR(100) UNIQUE
);

-- Table: Guest
CREATE TABLE Guest (
    GuestID INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Address NVARCHAR(200),
    PhoneNumber NVARCHAR(20),
    Email NVARCHAR(100),
    CONSTRAINT FK_Guest_Reservation FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID)
);

-- Table: Reservation
CREATE TABLE Reservation (
    ReservationID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    ReservationDate DATETIME NOT NULL DEFAULT GETDATE(),
    DepositPaid DECIMAL(10,2) CHECK (DepositPaid >= 0),
    TotalAmount DECIMAL(10,2) CHECK (TotalAmount >= 0),
    PaymentStatus NVARCHAR(20) CHECK (PaymentStatus IN ('Pending','Paid','Cancelled')) DEFAULT 'Pending',
    CONSTRAINT FK_Reservation_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- Table: ReservationDetails
CREATE TABLE ReservationDetails (
    ReservationDetailID INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID INT NOT NULL,
    AdvertisedID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    CONSTRAINT FK_ReservationDetails_Reservation FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID),
    CONSTRAINT FK_ReservationDetails_Advertised FOREIGN KEY (AdvertisedID) REFERENCES AdvertisedServicePackage(AdvertisedID)
);

-- 3. Insert sample data

-- Resorts
INSERT INTO Resort (Name, Address, Country, PhoneNumber, Email, Description)
VALUES 
('Resort Paradise', '1 Beach Rd, Sydney', 'Australia', '+61 2 1234 5678', 'info@resortparadise.com', 'Luxury beach resort'),
('Mountain Escape', '99 Alpine St, Melbourne', 'Australia', '+61 3 9876 5432', 'contact@mountainescape.com', 'Mountain view resort');

-- Facility Types
INSERT INTO FacilityType (Name, Description, Capacity)
VALUES
('Standard Room', 'Room with basic amenities', 2),
('Family Room', 'Spacious room for family', 4),
('Conference Hall', 'Hall for conferences', 100),
('Swimming Pool', 'Outdoor pool', 50);

-- Facilities
INSERT INTO Facility (ResortID, FacilityTypeID, Name, Description, Status)
VALUES
(1, 1, 'Room 101', 'Standard room with sea view', 'Available'),
(1, 4, 'Pool A', 'Outdoor pool near main building', 'Available');

-- Service Categories
INSERT INTO ServiceCategory (Code, Name, Description, Type)
VALUES
('AC', 'Accommodation', 'Room bookings', 'Accommodation'),
('FD', 'Food & Drinks', 'Meals and beverages', 'Food');

-- Service Items
INSERT INTO ServiceItem (ServiceCategoryID, Name, Description, BaseCost, BaseCurrency, Capacity)
VALUES
(1, 'Standard Room Night', 'Overnight stay in standard room', 150, 'AUD', 2),
(2, 'Buffet Breakfast', 'Breakfast at resort restaurant', 20, 'AUD', 50);

-- Advertised Service Packages
INSERT INTO AdvertisedServicePackage (Name, Description, StartDate, EndDate, AdvertisedPrice, AdvertisedCurrency, GracePeriodDays, Status)
VALUES
('Half-Board Package', 'Standard room with breakfast', '2026-02-01', '2026-12-31', 200, 'AUD', 2, 'Active');

-- Advertised Service Items
INSERT INTO AdvertisedServiceItems (AdvertisedID, ServiceID, Quantity)
VALUES
(1, 1, 1),
(1, 2, 2);

-- Customers
INSERT INTO Customer (Name, Address, PhoneNumber, Email)
VALUES
('John Doe', '123 Main St, Sydney', '+61 400 111 222', 'johndoe@email.com');

-- Reservations
INSERT INTO Reservation (CustomerID, DepositPaid, TotalAmount, PaymentStatus)
VALUES
(1, 30, 200, 'Pending');

-- Reservation Details
INSERT INTO ReservationDetails (ReservationID, AdvertisedID, Quantity, StartDate, EndDate)
VALUES
(1, 1, 1, '2026-03-01', '2026-03-02');-- CreateDB.sql
-- Database for HolidayFun Resort Management
-- Section 3: Database Implementation

-- 1. Create database
CREATE DATABASE HolidayFunDB;
GO

USE HolidayFunDB;
GO

-- 2. Create tables

-- Table: Resort
CREATE TABLE Resort (
    ResortID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Address NVARCHAR(200) NOT NULL,
    Country NVARCHAR(50) NOT NULL,
    PhoneNumber NVARCHAR(20),
    Email NVARCHAR(100),
    Description NVARCHAR(500)
);

-- Table: FacilityType
CREATE TABLE FacilityType (
    FacilityTypeID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(200),
    Capacity INT NOT NULL CHECK (Capacity > 0)
);

-- Table: Facility
CREATE TABLE Facility (
    FacilityID INT IDENTITY(1,1) PRIMARY KEY,
    ResortID INT NOT NULL,
    FacilityTypeID INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    Status NVARCHAR(20) CHECK (Status IN ('Available', 'Maintenance', 'Closed')) DEFAULT 'Available',
    CONSTRAINT FK_Facility_Resort FOREIGN KEY (ResortID) REFERENCES Resort(ResortID),
    CONSTRAINT FK_Facility_Type FOREIGN KEY (FacilityTypeID) REFERENCES FacilityType(FacilityTypeID)
);

-- Table: ServiceCategory
CREATE TABLE ServiceCategory (
    ServiceCategoryID INT IDENTITY(1,1) PRIMARY KEY,
    Code NVARCHAR(10) NOT NULL UNIQUE,
    Name NVARCHAR(50) NOT NULL,
    Description NVARCHAR(200),
    Type NVARCHAR(50)
);

-- Table: ServiceItem
CREATE TABLE ServiceItem (
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,
    ServiceCategoryID INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    Restrictions NVARCHAR(200),
    Status NVARCHAR(20) CHECK (Status IN ('Available','Unavailable')) DEFAULT 'Available',
    AvailableTimes NVARCHAR(100),
    BaseCost DECIMAL(10,2) NOT NULL CHECK (BaseCost >= 0),
    BaseCurrency NVARCHAR(10) NOT NULL,
    Capacity INT CHECK (Capacity > 0),
    CONSTRAINT FK_ServiceItem_Category FOREIGN KEY (ServiceCategoryID) REFERENCES ServiceCategory(ServiceCategoryID)
);

-- Table: AdvertisedServicePackage
CREATE TABLE AdvertisedServicePackage (
    AdvertisedID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    AdvertisedPrice DECIMAL(10,2) NOT NULL CHECK (AdvertisedPrice >= 0),
    AdvertisedCurrency NVARCHAR(10) NOT NULL,
    Inclusions NVARCHAR(500),
    Exclusions NVARCHAR(500),
    Status NVARCHAR(20) CHECK (Status IN ('Active','Inactive')) DEFAULT 'Active',
    GracePeriodDays INT CHECK (GracePeriodDays >= 0),
    AuthorizingEmployee NVARCHAR(100)
);

-- Table: AdvertisedServiceItems (link between package and service items)
CREATE TABLE AdvertisedServiceItems (
    AdvertisedID INT NOT NULL,
    ServiceID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    PRIMARY KEY (AdvertisedID, ServiceID),
    CONSTRAINT FK_AdvertisedService FOREIGN KEY (AdvertisedID) REFERENCES AdvertisedServicePackage(AdvertisedID),
    CONSTRAINT FK_AdvertisedItem_Service FOREIGN KEY (ServiceID) REFERENCES ServiceItem(ServiceID)
);

-- Table: Customer
CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Address NVARCHAR(200),
    PhoneNumber NVARCHAR(20),
    Email NVARCHAR(100) UNIQUE
);

-- Table: Guest
CREATE TABLE Guest (
    GuestID INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Address NVARCHAR(200),
    PhoneNumber NVARCHAR(20),
    Email NVARCHAR(100),
    CONSTRAINT FK_Guest_Reservation FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID)
);

-- Table: Reservation
CREATE TABLE Reservation (
    ReservationID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    ReservationDate DATETIME NOT NULL DEFAULT GETDATE(),
    DepositPaid DECIMAL(10,2) CHECK (DepositPaid >= 0),
    TotalAmount DECIMAL(10,2) CHECK (TotalAmount >= 0),
    PaymentStatus NVARCHAR(20) CHECK (PaymentStatus IN ('Pending','Paid','Cancelled')) DEFAULT 'Pending',
    CONSTRAINT FK_Reservation_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- Table: ReservationDetails
CREATE TABLE ReservationDetails (
    ReservationDetailID INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID INT NOT NULL,
    AdvertisedID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    CONSTRAINT FK_ReservationDetails_Reservation FOREIGN KEY (ReservationID) REFERENCES Reservation(ReservationID),
    CONSTRAINT FK_ReservationDetails_Advertised FOREIGN KEY (AdvertisedID) REFERENCES AdvertisedServicePackage(AdvertisedID)
);

-- 3. Insert sample data

-- Resorts
INSERT INTO Resort (Name, Address, Country, PhoneNumber, Email, Description)
VALUES 
('Resort Paradise', '1 Beach Rd, Sydney', 'Australia', '+61 2 1234 5678', 'info@resortparadise.com', 'Luxury beach resort'),
('Mountain Escape', '99 Alpine St, Melbourne', 'Australia', '+61 3 9876 5432', 'contact@mountainescape.com', 'Mountain view resort');

-- Facility Types
INSERT INTO FacilityType (Name, Description, Capacity)
VALUES
('Standard Room', 'Room with basic amenities', 2),
('Family Room', 'Spacious room for family', 4),
('Conference Hall', 'Hall for conferences', 100),
('Swimming Pool', 'Outdoor pool', 50);

-- Facilities
INSERT INTO Facility (ResortID, FacilityTypeID, Name, Description, Status)
VALUES
(1, 1, 'Room 101', 'Standard room with sea view', 'Available'),
(1, 4, 'Pool A', 'Outdoor pool near main building', 'Available');

-- Service Categories
INSERT INTO ServiceCategory (Code, Name, Description, Type)
VALUES
('AC', 'Accommodation', 'Room bookings', 'Accommodation'),
('FD', 'Food & Drinks', 'Meals and beverages', 'Food');

-- Service Items
INSERT INTO ServiceItem (ServiceCategoryID, Name, Description, BaseCost, BaseCurrency, Capacity)
VALUES
(1, 'Standard Room Night', 'Overnight stay in standard room', 150, 'AUD', 2),
(2, 'Buffet Breakfast', 'Breakfast at resort restaurant', 20, 'AUD', 50);

-- Advertised Service Packages
INSERT INTO AdvertisedServicePackage (Name, Description, StartDate, EndDate, AdvertisedPrice, AdvertisedCurrency, GracePeriodDays, Status)
VALUES
('Half-Board Package', 'Standard room with breakfast', '2026-02-01', '2026-12-31', 200, 'AUD', 2, 'Active');

-- Advertised Service Items
INSERT INTO AdvertisedServiceItems (AdvertisedID, ServiceID, Quantity)
VALUES
(1, 1, 1),
(1, 2, 2);

-- Customers
INSERT INTO Customer (Name, Address, PhoneNumber, Email)
VALUES
('John Doe', '123 Main St, Sydney', '+61 400 111 222', 'johndoe@email.com');

-- Reservations
INSERT INTO Reservation (CustomerID, DepositPaid, TotalAmount, PaymentStatus)
VALUES
(1, 30, 200, 'Pending');

-- Reservation Details
INSERT INTO ReservationDetails (ReservationID, AdvertisedID, Quantity, StartDate, EndDate)
VALUES
(1, 1, 1, '2026-03-01', '2026-03-02');
