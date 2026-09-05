## 1. What is RaceDay?

RaceDay is a web system for South African road running, walking and cycling events (like Comrades, Soweto Marathon, Cape Town Cycle Tour, park runs, etc.).

There are two types of users:

- **Organiser** → Creates events, manages categories, captures results, sees who enrolled.
- **Participant** → Creates account, browses events, enters a category, sees their own results.

---

## 2. The 6 Database Tables (ERD)

You must have at least 6 entities. Here they are and how they connect:

### Table 1: Roles
- Only two possible values: Organiser and Participant.
- Why separate table? Makes it easy to add more roles later and keeps data clean.

### Table 2: Users
- Every person in the system (organisers and participants).
- Linked to Roles via RoleId (Foreign Key).
- Stores name, email, password hash, phone, date of birth.

### Table 3: Events
- The actual race/cycle/walk.
- Linked to the Organiser who created it (OrganiserId → Users).
- Has title, date, location, city, province, status, image URL (for later Azure Blob).

### Table 4: Categories
- Different options under one event (e.g. 5km, 10km, Half Marathon, Full Marathon).
- Linked to Events (EventId).
- If an event is deleted, its categories are also deleted (ON DELETE CASCADE).

### Table 5: Enrolments
- When a Participant signs up for a specific Category.
- Links ParticipantId → Users and CategoryId → Categories.
- A person can only enter the same category once (UNIQUE constraint).

### Table 6: Results
- The finishing time and position for one enrolment.
- One-to-one with Enrolments (one result per enrolment).
- Captured by an Organiser.

**Relationships summary (for the video):**
- One Role → Many Users
- One Organiser → Many Events
- One Event → Many Categories
- One Participant → Many Enrolments
- One Category → Many Enrolments
- One Enrolment → One Result

---

## 3. How to Explain the SQL Script

When you run the script live in SSMS, talk through these points:

1. **We drop and recreate the database** so the script can be run many times without errors.
2. **We create the 6 tables in the correct order** (Roles first, then Users, then Events, etc.) because of foreign keys.
3. **Primary Keys** = IDENTITY(1,1) so SQL Server automatically gives unique numbers.
4. **Foreign Keys** connect the tables and protect data integrity.
5. **CHECK constraints** stop invalid data (e.g. Status can only be certain values).
6. **UNIQUE constraints** stop duplicates (email, and one enrolment per category).
7. **Seed data** meets the minimum requirements:
   - 2 Organisers
   - 2 Participants
   - 3 Events
   - Categories for each event
   - Sample enrolments and results

---

## 4. API Endpoint Plan – What to Say

You planned endpoints for:

- Authentication (register + login)
- User Profile
- Events (create, edit, delete, list)
- Categories
- Enrolments (enter event, view own, organiser view)
- Results (capture, view)

Every endpoint has:
- HTTP Method (GET, POST, PUT, DELETE)
- Route (always starts with /api/)
- Description
- Role Required
- Request Body
- Expected Response (including error codes)

This shows you understood the system **before** writing any C# code in Part 2.

---

## 5. What the Marker Expects in the Video

Speak clearly and show:

1. The ERD (open the Mermaid diagram or the image).
2. Explain why you chose these 6 tables and the relationships.
3. Open the API Endpoint Plan and show a few important endpoints.
4. Open SSMS → run the full SQL script live.
5. After it runs, show the tables and some of the seed data with simple SELECT statements.

Example SELECTs you can run after the script:

```sql
SELECT * FROM Roles;
SELECT * FROM Users;
SELECT * FROM Events;
SELECT * FROM Categories;
SELECT * FROM Enrolments;
SELECT * FROM Results;
```

---

## 6. Files You Must Have in /docs

- RaceDay_ERD.md (or the PNG/PDF version of the diagram)
- API_Endpoint_Plan.md
- RaceDay_Database.sql
- How_to_Explain_This_Project.md (this file – optional but helpful)

Also required in the root:
- README.md
- .github/workflows/validate-docs.yml

---

