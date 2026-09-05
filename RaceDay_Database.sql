-- ============================================================
-- RaceDay Database Script (Part 1)
-- Easy-to-explain version for students
-- ============================================================

USE master;
GO

-- Delete the database if it already exists (so the script can be run again cleanly)
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'RaceDayDB')
BEGIN
    ALTER DATABASE RaceDayDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDayDB;
END
GO

-- Create a fresh database
CREATE DATABASE RaceDayDB;
GO

USE RaceDayDB;
GO

------------------------------------------------------------
-- 1. ROLES TABLE
-- Stores the two user roles: Organiser and Participant
------------------------------------------------------------
CREATE TABLE Roles (
    RoleId      INT PRIMARY KEY IDENTITY(1,1),
    RoleName    NVARCHAR(50) NOT NULL UNIQUE,   -- "Organiser" or "Participant"
    Description NVARCHAR(200)
);
GO

------------------------------------------------------------
-- 2. USERS TABLE
-- Stores all users (both Organisers and Participants)
------------------------------------------------------------
CREATE TABLE Users (
    UserId          INT PRIMARY KEY IDENTITY(1,1),
    RoleId          INT NOT NULL,               -- Links to Roles table
    FirstName       NVARCHAR(100) NOT NULL,
    LastName        NVARCHAR(100) NOT NULL,
    Email           NVARCHAR(256) NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(256) NOT NULL,     -- We never store plain passwords
    PhoneNumber     NVARCHAR(20),
    DateOfBirth     DATE,
    CreatedAt       DATETIME2 DEFAULT SYSUTCDATETIME(),
    IsActive        BIT DEFAULT 1,

    -- Foreign Key
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleId) REFERENCES Roles(RoleId)
);
GO

------------------------------------------------------------
-- 3. EVENTS TABLE
-- Stores the race / cycle / walk events
------------------------------------------------------------
CREATE TABLE Events (
    EventId         INT PRIMARY KEY IDENTITY(1,1),
    OrganiserId     INT NOT NULL,               -- Who created the event
    Title           NVARCHAR(200) NOT NULL,
    Description     NVARCHAR(MAX),
    EventDate       DATE NOT NULL,
    StartTime       TIME,
    Location        NVARCHAR(300) NOT NULL,
    City            NVARCHAR(100) NOT NULL,
    Province        NVARCHAR(50) NOT NULL,
    Status          NVARCHAR(20) DEFAULT 'Draft',  -- Draft, Published, Cancelled, Completed
    MaxParticipants INT,
    ImageUrl        NVARCHAR(500),              -- Ready for Azure Blob later
    CreatedAt       DATETIME2 DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2,

    -- Foreign Key
    CONSTRAINT FK_Events_Organiser FOREIGN KEY (OrganiserId) REFERENCES Users(UserId),

    -- Check constraint for allowed status values
    CONSTRAINT CK_Events_Status CHECK (Status IN ('Draft', 'Published', 'Cancelled', 'Completed'))
);
GO

------------------------------------------------------------
-- 4. CATEGORIES TABLE
-- Different distances / options under one event
-- (e.g. 5km, 10km, Half Marathon)
------------------------------------------------------------
CREATE TABLE Categories (
    CategoryId          INT PRIMARY KEY IDENTITY(1,1),
    EventId             INT NOT NULL,           -- Belongs to which event
    Name                NVARCHAR(100) NOT NULL, -- e.g. "10km Road Race"
    DistanceKm          DECIMAL(6,2) NOT NULL,
    EntryFee            DECIMAL(10,2) DEFAULT 0,
    AgeMin              INT,
    AgeMax              INT,
    GenderRestriction   NVARCHAR(10) DEFAULT 'None', -- None, Male, Female
    MaxEntries          INT,
    CreatedAt           DATETIME2 DEFAULT SYSUTCDATETIME(),

    -- Foreign Key (cascade delete: if event is deleted, its categories are also deleted)
    CONSTRAINT FK_Categories_Events FOREIGN KEY (EventId) 
        REFERENCES Events(EventId) ON DELETE CASCADE,

    -- Check constraints
    CONSTRAINT CK_Categories_Gender CHECK (GenderRestriction IN ('None', 'Male', 'Female')),
    CONSTRAINT CK_Categories_Distance CHECK (DistanceKm > 0)
);
GO

------------------------------------------------------------
-- 5. ENROLMENTS TABLE
-- When a Participant enters a specific category
------------------------------------------------------------
CREATE TABLE Enrolments (
    EnrolmentId     INT PRIMARY KEY IDENTITY(1,1),
    ParticipantId   INT NOT NULL,               -- Who is entering
    CategoryId      INT NOT NULL,               -- Which category they entered
    EnrolmentDate   DATETIME2 DEFAULT SYSUTCDATETIME(),
    Status          NVARCHAR(20) DEFAULT 'Confirmed', -- Pending, Confirmed, Cancelled, Completed
    BibNumber       NVARCHAR(20),
    PaymentStatus   NVARCHAR(20) DEFAULT 'Pending',   -- Pending, Paid, Refunded
    Notes           NVARCHAR(500),

    -- Foreign Keys
    CONSTRAINT FK_Enrolments_Participant FOREIGN KEY (ParticipantId) REFERENCES Users(UserId),
    CONSTRAINT FK_Enrolments_Category FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId),

    -- A participant can only enter the same category once
    CONSTRAINT UQ_Enrolments_Participant_Category UNIQUE (ParticipantId, CategoryId),

    -- Check constraints
    CONSTRAINT CK_Enrolments_Status CHECK (Status IN ('Pending', 'Confirmed', 'Cancelled', 'Completed')),
    CONSTRAINT CK_Enrolments_Payment CHECK (PaymentStatus IN ('Pending', 'Paid', 'Refunded'))
);
GO

------------------------------------------------------------
-- 6. RESULTS TABLE
-- Race results for a specific enrolment
------------------------------------------------------------
CREATE TABLE Results (
    ResultId            INT PRIMARY KEY IDENTITY(1,1),
    EnrolmentId         INT NOT NULL UNIQUE,    -- One result per enrolment
    FinishTime          TIME,                   -- Can be NULL if DNF
    OverallPosition     INT,
    CategoryPosition    INT,
    Status              NVARCHAR(20) DEFAULT 'Finished', -- Finished, DNF, DNS, DQ
    ChipTime            TIME,
    GunTime             TIME,
    CapturedAt          DATETIME2 DEFAULT SYSUTCDATETIME(),
    CapturedByUserId    INT NOT NULL,           -- Which Organiser captured it

    -- Foreign Keys
    CONSTRAINT FK_Results_Enrolment FOREIGN KEY (EnrolmentId) REFERENCES Enrolments(EnrolmentId),
    CONSTRAINT FK_Results_CapturedBy FOREIGN KEY (CapturedByUserId) REFERENCES Users(UserId),

    -- Check constraint
    CONSTRAINT CK_Results_Status CHECK (Status IN ('Finished', 'DNF', 'DNS', 'DQ'))
);
GO

------------------------------------------------------------
-- INDEXES (for faster queries)
------------------------------------------------------------
CREATE INDEX IX_Events_OrganiserId ON Events(OrganiserId);
CREATE INDEX IX_Events_EventDate ON Events(EventDate);
CREATE INDEX IX_Categories_EventId ON Categories(EventId);
CREATE INDEX IX_Enrolments_ParticipantId ON Enrolments(ParticipantId);
CREATE INDEX IX_Enrolments_CategoryId ON Enrolments(CategoryId);
GO

------------------------------------------------------------
-- SEED DATA (Sample data required by the assignment)
------------------------------------------------------------

-- 1. Insert the two Roles
INSERT INTO Roles (RoleName, Description) VALUES
('Organiser', 'Can create and manage events, categories and capture results'),
('Participant', 'Can browse events, enrol and view personal results');
GO

-- 2. Insert Users (2 Organisers + 2 Participants)
-- PasswordHash is just a placeholder for now
INSERT INTO Users (RoleId, FirstName, LastName, Email, PasswordHash, PhoneNumber, DateOfBirth) VALUES
(1, 'Thabo', 'Mokoena', 'thabo.mokoena@raceday.co.za', 'hashed_password_123', '0821234567', '1985-03-12'),  -- Organiser
(1, 'Sarah', 'van der Berg', 'sarah.vdberg@capetowncycle.org', 'hashed_password_123', '0839876543', '1978-07-22'), -- Organiser
(2, 'Lerato', 'Dlamini', 'lerato.dlamini@gmail.com', 'hashed_password_123', '0712345678', '1995-11-05'),        -- Participant
(2, 'Johan', 'Pretorius', 'johan.pretorius@outlook.com', 'hashed_password_123', '0845678901', '1990-01-30');  -- Participant
GO

-- 3. Insert 3 Events
INSERT INTO Events (OrganiserId, Title, Description, EventDate, StartTime, Location, City, Province, Status, MaxParticipants) VALUES
(1, 'Soweto Marathon 2026', 
 'The iconic Soweto Marathon through the historic streets of Soweto.',
 '2026-11-01', '06:00', 'FNB Stadium, Soccer City', 'Johannesburg', 'Gauteng', 'Published', 15000),

(1, 'Two Oceans Training Run', 
 'Supported training run for athletes preparing for the Two Oceans Marathon.',
 '2026-03-15', '05:30', 'University of Cape Town', 'Cape Town', 'Western Cape', 'Published', 500),

(2, 'Cape Town Cycle Tour Fun Ride', 
 'A fun non-competitive cycle ride finishing on Sea Point promenade.',
 '2026-03-08', '07:00', 'Cape Town Stadium', 'Cape Town', 'Western Cape', 'Published', 8000);
GO

-- 4. Insert Categories for each Event
-- Soweto Marathon categories
INSERT INTO Categories (EventId, Name, DistanceKm, EntryFee, AgeMin, GenderRestriction, MaxEntries) VALUES
(1, 'Full Marathon', 42.20, 450.00, 18, 'None', 5000),
(1, 'Half Marathon', 21.10, 350.00, 16, 'None', 6000),
(1, '10km Road Race', 10.00, 200.00, 14, 'None', 4000);

-- Two Oceans Training categories
INSERT INTO Categories (EventId, Name, DistanceKm, EntryFee, AgeMin, GenderRestriction, MaxEntries) VALUES
(2, '56km Ultra Simulation', 56.00, 150.00, 20, 'None', 200),
(2, '21km Supported Run', 21.10, 100.00, 16, 'None', 300);

-- Cape Town Cycle Tour categories
INSERT INTO Categories (EventId, Name, DistanceKm, EntryFee, AgeMin, GenderRestriction, MaxEntries) VALUES
(3, '109km Classic', 109.00, 0.00, 18, 'None', 3000),
(3, '42km Fun Ride', 42.00, 0.00, 12, 'None', 5000);
GO

-- 5. Insert sample Enrolments
INSERT INTO Enrolments (ParticipantId, CategoryId, Status, BibNumber, PaymentStatus, Notes) VALUES
(3, 2, 'Confirmed', 'H-1024', 'Paid', 'First half marathon'),          -- Lerato → Soweto Half Marathon
(3, 5, 'Confirmed', 'T-045',  'Paid', NULL),                           -- Lerato → Two Oceans 21km
(4, 1, 'Confirmed', 'M-0881', 'Paid', 'Comrades qualifier'),           -- Johan → Soweto Full Marathon
(4, 6, 'Confirmed', 'C-3321', 'Paid', NULL),                           -- Johan → Cape Town 109km
(3, 7, 'Confirmed', 'C-5102', 'Pending', 'Waiting for payment');       -- Lerato → Cape Town 42km
GO

-- 6. Insert sample Results
INSERT INTO Results (EnrolmentId, FinishTime, OverallPosition, CategoryPosition, Status, ChipTime, GunTime, CapturedByUserId) VALUES
(1, '01:42:35', 145, 32, 'Finished', '01:42:28', '01:42:35', 1),   -- Lerato's Half Marathon result
(3, '03:58:12', 892, 210, 'Finished', '03:57:55', '03:58:12', 1);  -- Johan's Full Marathon result
GO

PRINT '=============================================';
PRINT 'RaceDayDB created successfully!';
PRINT 'Tables: Roles, Users, Events, Categories, Enrolments, Results';
PRINT '=============================================';
GO
