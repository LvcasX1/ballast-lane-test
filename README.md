# Ballast Lane Test – Rails API

A Rails 8 API-only application for a simple library system. It supports users (members and librarians), session-based token auth (Bearer tokens), books CRUD, borrowing/return flows, and role-based dashboards.

## Tech stack
- Ruby 3.4.x, Rails 8 (API-only)
- PostgreSQL, Puma, Rack 3
- Auth: token via `Authorization: Bearer <token>`

## Quick start
1) Prerequisites
- Ruby 3.4.x (rbenv/rvm)
- PostgreSQL running locally, you can use the following command:

```sh
docker run --rm -it \
  -p 5432:5432 \
  --name test_postgres \
  -e POSTGRES_PASSWORD=test \
  postgres:latest
```

2) Install dependencies
- bundle install

3) Database setup
- bin/rails db:prepare
- Load seed data using fixtures into development:
  - RAILS_ENV=development bin/rails db:fixtures:load

PostgreSQL setup (local or Docker):
- Local: update `config/database.yml` to match your local credentials (user, password, host/port).

Then point `config/database.yml` to host `localhost` (or `127.0.0.1`), user `postgres`, and password `test`.

4) Run the server
  - `bin/rails s` or `rails server`

5) Run tests
  - `bin/rails test` or `rails test`

## Default users (from fixtures)
- Librarian: librarian1@library.com / password
- Member:    member1@example.com / password

## Authentication
- Sign up: `POST /sign-up` (returns `auth_token`)
- Log in:  `POST /session` (returns `auth_token`)
- Log out: `DELETE /session`
- Send `Authorization: Bearer <token>` on subsequent requests

## Key endpoints
- Books: 
  - `GET /books`
  - `GET /books/:id`
  - `POST /books`
  - `PATCH/PUT /books/:id`
  - `DELETE /books/:id`
  - Requires auth. Create/Update/Delete require librarian role.
- Users: 
  - `GET /users`
  - `GET /users/:id`
  - `PATCH/PUT /users/:id`
  - `DELETE /users/:id`
  - Sign up via `POST /sign-up` (no auth). Others require auth.
- Borrowings: 
  - `POST /borrowings` (member only)
  - `GET /borrowings/:id`
  - `POST /borrowings/:id/retur` (librarian only)
- Dashboards: 
  - `GET /dashboard/librarian` (librarian)
  - `GET /dashboard/member` (member)

## Bruno API collection
A Bruno collection is included in `bruno/` with a `local` environment.
- Set `{{url}}` and use the `session/login` request to obtain a token.
- Use librarian login for book admin and returns, member login for borrowing.

Setup Bruno
1. Install Bruno
   - macOS (Homebrew):
     ```sh
     brew install --cask bruno
     ```
   - Or download installer: https://www.usebruno.com/downloads
2. Load this project’s collection
   - Open Bruno → File → Open Collection…
   - Select the repository’s `bruno/` folder (or the `bruno/bruno.json` file).
   - You should see folders like: `session`, `users`, `books`, `borrowings`, `api`, and `environments`.
3. Select environment: choose `environments/local` and set variables:
   - url: `http://localhost:3000`
   - token: leave empty (it will be set by login requests)
   - book_id, user_id, borrowing_id, reset_token: optional; many are auto-populated by scripts
4. Authenticate:
   - Run `session/login.bru` for a librarian or `session/login_member.bru` for a member.
   - The post-response script stores `auth_token` into the `token` env var.
5. Exercise endpoints:
   - `books/create_book.bru` captures `book_id` into the environment.
   - `borrowings/create.bru` uses `{{book_id}}` and saves `borrowing_id`.
   - `borrowings/return.bru` requires a librarian token.
   - Dashboards: `api/librarian_dashboard.bru` (librarian) and `api/member_dashboard.bru` (member).
6. Password reset flow:
   - `passwords/request_reset.bru` triggers email delivery; set `reset_token` manually in the environment to test `edit`/`update` requests.
7. Reset/rotate token:
   - Run `session/logout.bru` or clear the `token` variable in the environment.

Note
- Requests include `Authorization: Bearer {{token}}` headers; ensure the environment is selected before running.

## Diagrams

### High-level flow
```mermaid
flowchart LR
  subgraph Client
    A[Sign Up / Login]
    B[Use Bearer Token]
  end

  subgraph API[Rails API]
    U[Users Controller]
    S[Sessions Controller]
    BK[Books Controller]
    BR[Borrowings Controller]
    D[Dashboards Controller]
  end

  DB[(PostgreSQL)]

  A -->|POST /sign-up or /session| S
  S -->|auth_token| B
  B -->|Authorization: Bearer| BK & BR & D & U

  BK <--> DB
  BR <--> DB
  U  <--> DB
  D  --> BK & BR
```

### Components
```mermaid
graph LR
  Client[API Clients / Bruno]
  Rails[Rails 8 API]
  Ctrls[Controllers: Users, Sessions, Books, Borrowings, Dashboards]
  Models[Models: User, Book, Borrowing]
  PG[(PostgreSQL)]

  Client --> Rails --> Ctrls --> Models --> PG
```

### Sequence: Member borrows a book
```mermaid
sequenceDiagram
  participant C as Client
  participant S as SessionsController
  participant B as BorrowingsController
  participant M as Models
  participant DB as PostgreSQL

  C->>S: POST /session (email, password)
  S-->>C: 200 { auth_token }
  C->>B: POST /borrowings (Authorization: Bearer, book_id)
  B->>M: Validate available copies & not already borrowed
  M->>DB: INSERT borrowings
  B-->>C: 201 { borrowing payload }
```

## Notes
- Status 422 is named 'Unprocessable Content' per RFC 9110; use `status: :unprocessable_content`.
- All non-sign-up endpoints require authentication; librarian-only endpoints are enforced server-side.

## Troubleshooting
- Ensure Postgres is running and `config/database.yml` is correct.
- If fixtures don't load: confirm `test/fixtures/` exists and run with `RAILS_ENV=development`.
- Logs: `log/development.log`.
