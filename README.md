# RaceDay – Event Management Platform

**Portfolio of Evidence (PoE) – Part 1: System Planning and Database**

RaceDay is a full-stack web-based event management system for the South African road running, walking and cycling community (Comrades, Soweto Marathon, Cape Town Cycle Tour, park runs, etc.).

## Two Roles

| Role | What they can do |
|------|------------------|
| **Organiser** | Create, edit and delete events, manage categories, capture results, view enrolments |
| **Participant** | Create account, browse events, enter a category, view own enrolments and results |

## Part 1 Deliverables (all inside /docs)

| File | Purpose |
|------|---------|
| `docs/RaceDay_ERD.md` | Entity Relationship Diagram + full explanation |
| `docs/API_Endpoint_Plan.md` | Complete list of every API endpoint |
| `docs/RaceDay_Database.sql` | Full SQL Server script (creates tables + seed data) |
| `docs/How_to_Explain_This_Project.md` | Student guide – how to explain everything in the video |

## How to Run the SQL Script

1. Open SQL Server Management Studio (SSMS)
2. Connect to your SQL Server instance
3. Open `docs/RaceDay_Database.sql`
4. Execute the whole script (F5)
5. The database `RaceDayDB` will be created with all tables and sample data

## GitHub Actions CI/CD

The workflow in `.github/workflows/validate-docs.yml` checks that the required files exist in the `/docs` folder.

**Screenshot of successful green build:**  
*(Paste your green CI/CD screenshot here before submitting)*

## Video Presentation

**Unlisted YouTube link:**  
*(Paste your video link here)*

In the video you must:
- Explain the ERD decisions
- Explain the API endpoint plan
- Run the SQL script live in SSMS

## Repository Structure

```
/
├── docs/
│   ├── RaceDay_ERD.md
│   ├── API_Endpoint_Plan.md
│   ├── RaceDay_Database.sql
│   └── How_to_Explain_This_Project.md
├── .github/workflows/
│   └── validate-docs.yml
└── README.md
```

## AI Tool Disclosure

AI assistance was used for structuring documents and generating consistent formatting. All design decisions, entity choices and explanations were reviewed and owned by the student.
