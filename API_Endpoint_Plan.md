# RaceDay API Endpoint Plan

**Part 1 – System Planning**  
This document defines every planned RESTful endpoint before any code is written in Part 2.  
The final implementation in Part 2 must closely match this plan.

**Base URL:** `/api`  
**Authentication:** JWT Bearer token (issued by `/api/auth/login`)  
**Roles:** `None` (public), `Any` (authenticated), `Organiser`, `Participant`

---

## 1. Authentication

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| POST | `/api/auth/register` | Creates a new user account (Participant or Organiser). Hashes the password and returns a confirmation. | None | `{ "firstName": "", "lastName": "", "email": "", "password": "", "role": "Participant"\|"Organiser", "phoneNumber": "", "dateOfBirth": "YYYY-MM-DD" }` | `201 Created` – user summary (no password)<br>`400 Bad Request` – validation errors<br>`409 Conflict` – email already exists |
| POST | `/api/auth/login` | Authenticates a user and returns a JWT access token. | None | `{ "email": "", "password": "" }` | `200 OK` – `{ "token": "...", "expiresIn": 3600, "user": { ... } }`<br>`401 Unauthorized` – invalid credentials |

---

## 2. User Profile

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | `/api/users/me` | Returns the profile of the currently authenticated user. | Any | None | `200 OK` – full user profile (no password hash)<br>`401 Unauthorized` |
| PUT | `/api/users/me` | Updates the authenticated user’s profile details (name, phone, DOB). Email cannot be changed. | Any | `{ "firstName": "", "lastName": "", "phoneNumber": "", "dateOfBirth": "YYYY-MM-DD" }` | `200 OK` – updated profile<br>`400 Bad Request`<br>`401 Unauthorized` |
| GET | `/api/users/{id}` | Returns a public summary of a user (for organisers viewing participant details on enrolments). | Organiser | None | `200 OK` – limited user info<br>`404 Not Found`<br>`403 Forbidden` |

---

## 3. Events

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | `/api/events` | Lists all published events (supports optional query filters: city, province, dateFrom, dateTo, status). | None | None | `200 OK` – array of event summaries |
| GET | `/api/events/{id}` | Returns full details of a single event including its categories. | None | None | `200 OK` – event + categories<br>`404 Not Found` |
| POST | `/api/events` | Creates a new event. The authenticated user becomes the organiser. | Organiser | `{ "title": "", "description": "", "eventDate": "YYYY-MM-DD", "startTime": "HH:mm", "location": "", "city": "", "province": "", "status": "Draft"\|"Published", "maxParticipants": 0, "imageUrl": "" }` | `201 Created` – created event<br>`400 Bad Request`<br>`401/403` |
| PUT | `/api/events/{id}` | Updates an existing event. Only the owning organiser may update. | Organiser (owner) | Same as POST (partial allowed) | `200 OK` – updated event<br>`404 Not Found`<br>`403 Forbidden` – not the owner |
| DELETE | `/api/events/{id}` | Soft-deletes or cancels an event (sets status to Cancelled). Only the owner. | Organiser (owner) | None | `204 No Content`<br>`404 Not Found`<br>`403 Forbidden` |
| GET | `/api/events/my` | Lists all events created by the authenticated organiser. | Organiser | None | `200 OK` – array of events |

---

## 4. Categories

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | `/api/events/{eventId}/categories` | Lists all categories belonging to an event. | None | None | `200 OK` – array of categories<br>`404 Not Found` – event does not exist |
| GET | `/api/categories/{id}` | Returns a single category with parent event info. | None | None | `200 OK`<br>`404 Not Found` |
| POST | `/api/events/{eventId}/categories` | Adds a new category to an event. Only the event organiser. | Organiser (owner) | `{ "name": "", "distanceKm": 0, "entryFee": 0, "ageMin": null, "ageMax": null, "genderRestriction": "None", "maxEntries": null }` | `201 Created`<br>`400 Bad Request`<br>`403 Forbidden`<br>`404 Not Found` |
| PUT | `/api/categories/{id}` | Updates an existing category. Only the event organiser. | Organiser (owner) | Same fields as POST (partial) | `200 OK`<br>`404 Not Found`<br>`403 Forbidden` |
| DELETE | `/api/categories/{id}` | Deletes a category (only if no enrolments exist). | Organiser (owner) | None | `204 No Content`<br>`409 Conflict` – has enrolments<br>`403/404` |

---

## 5. Event Enrolments

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| POST | `/api/enrolments` | Registers the authenticated participant into a category. | Participant | `{ "categoryId": 0, "notes": "" }` | `201 Created` – enrolment record<br>`400 Bad Request`<br>`409 Conflict` – already enrolled or category full<br>`404 Not Found` – category does not exist |
| GET | `/api/enrolments/me` | Lists all enrolments belonging to the authenticated participant. | Participant | None | `200 OK` – array of enrolments with event & category details |
| GET | `/api/events/{eventId}/enrolments` | Lists all enrolments for a specific event (organiser view). | Organiser (owner) | None | `200 OK` – array of enrolments + participant info<br>`403 Forbidden`<br>`404 Not Found` |
| GET | `/api/enrolments/{id}` | Returns a single enrolment. Participant can only view own; organiser can view any under their events. | Any (owner rules) | None | `200 OK`<br>`403 Forbidden`<br>`404 Not Found` |
| PUT | `/api/enrolments/{id}/cancel` | Cancels an enrolment (sets status to Cancelled). Participant may cancel own; organiser may cancel any under their event. | Participant (own) or Organiser (owner) | None | `200 OK` – updated enrolment<br>`400 Bad Request` – already completed<br>`403/404` |
| PUT | `/api/enrolments/{id}/bib` | Assigns or updates a bib number (organiser only). | Organiser (owner) | `{ "bibNumber": "" }` | `200 OK`<br>`403/404` |

---

## 6. Results

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| POST | `/api/results` | Captures a result for an enrolment. Only the event organiser. | Organiser (owner) | `{ "enrolmentId": 0, "finishTime": "HH:mm:ss", "overallPosition": 0, "categoryPosition": 0, "status": "Finished"\|"DNF"\|"DNS"\|"DQ", "chipTime": "HH:mm:ss", "gunTime": "HH:mm:ss" }` | `201 Created`<br>`400 Bad Request`<br>`409 Conflict` – result already exists<br>`403 Forbidden`<br>`404 Not Found` |
| GET | `/api/results/me` | Returns all results belonging to the authenticated participant. | Participant | None | `200 OK` – array of results with event/category context |
| GET | `/api/events/{eventId}/results` | Returns the official results list for an event (public after published). | None | None | `200 OK` – ordered results<br>`404 Not Found` |
| GET | `/api/results/{id}` | Returns a single result. | Any | None | `200 OK`<br>`404 Not Found` |
| PUT | `/api/results/{id}` | Updates an existing result (e.g. correct a time or status). | Organiser (owner) | Same fields as POST (partial) | `200 OK`<br>`403/404` |
| DELETE | `/api/results/{id}` | Removes a result (rare – only before final publication). | Organiser (owner) | None | `204 No Content`<br>`403/404` |

---

## Additional / Supporting Endpoints (recommended)

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| GET | `/api/events/{id}/weather` | Returns live weather forecast for the event location (external integration – Part 3+). | None | None | `200 OK` – weather payload<br>`503 Service Unavailable` |
| GET | `/api/health` | Simple health-check endpoint for CI/CD and monitoring. | None | None | `200 OK` – `{ "status": "Healthy" }` |

---

## Design Notes

1. **Role enforcement** will be implemented with `[Authorize(Roles = "Organiser")]` and resource-based checks (ownership) in Part 2.
2. **Pagination** should be added to list endpoints (`?page=1&pageSize=20`) in the actual implementation.
3. **Filtering & sorting** on `/api/events` is planned but query parameters are not shown in every row for brevity.
4. All write operations that accept a body expect `application/json`.
5. Consistent error response shape: `{ "message": "...", "errors": { ... } }`.
6. This plan covers every functional requirement listed for authentication, profile, events, categories, enrolments and results.

**Version:** 1.0 (Part 1 Planning)  
**Date:** September 2026
