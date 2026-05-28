# DBWP Sample Questions

## Question 1: Databases [30 marks]

> **Note:** All tables can have hundreds of data entries. This is denoted by `…`.

### 1(a) Create a `Furniture` table [5 marks]

Imagine you are working as a database developer and are given the following table in Excel format. The company you work for has asked you to add it to their relational database management system.

Write an SQL query that creates a table called `Furniture` with the same structure. Include the specification of primary key(s). Do **not** insert any data into the table.

| FurnitureID | ItemName             | Material       | Price   | StockQuantity |
|------------:|----------------------|----------------|--------:|--------------:|
| 1           | Eames Chair          | Leather/Wood   | 450.00  | 12            |
| 2           | Billy Bookcase       | Particle Board | 89.99   | 45            |
| 3           | Marble Dining Table  | Stone          | 1200.00 | 3             |
| 4           | Task Lamp            | Steel          | 35.50   | 28            |
| …           | …                    | …              | …       | …             |

---

### 1(b) Normalisation scenario: Pet grooming appointments [15 marks]

A local **Pet Grooming & Boarding** shop uses a single spreadsheet to track appointments.

The owner is complaining that:

- When a customer changes their phone number, they must update it in ten different places.
- If they delete an appointment, they sometimes lose the owner's contact information entirely.

#### Table 1: Pet Grooming Appointments

`ApptID` stands for appointment ID.

| ApptID | OwnerName  | OwnerPhone | PetName | PetType | Service        | ServicePrice |
|-------:|------------|------------|---------|---------|----------------|-------------:|
| 501    | Sarah Chen | 555-1234   | Barnaby | Dog     | Full Groom     | $60          |
| 502    | Mike Ross  | 555-9876   | Luna    | Cat     | Nail Trim      | $20          |
| 503    | Sarah Chen | 555-1234   | Felix   | Cat     | Full Groom     | $45          |
| 504    | Sarah Chen | 555-1234   | Barnaby | Dog     | Teeth Brushing | $15          |
| …      | …          | …          | …       | …       | …              | …            |

#### 1(b)(i) Identify anomalies [5 marks]

What anomalies can be identified based on this scenario? Explain your answer.

#### 1(b)(ii) Normalise into 3NF [10 marks]

If you normalise **Table 1** into **Third Normal Form (3NF)**:

- How many tables will you end up with?
- What will their columns be?
- What will the primary and foreign keys be?

Your answer should use the following form:

```text
[Table1_Name]: [Column1_Name] [Column2_Name] …
[Table2_Name]: [Column1_Name] [Column2_Name] …
[Table3_Name]: [Column1_Name] [Column2_Name] …
```

If a column is selected as a primary or foreign key, use:

```text
[Column1_Name] (PK)
[Column1_Name] (FK)
```

---

### 1(c) Joins and filtering in a cinema database [10 marks]

Consider a cinema database comprising two tables.

#### Table 2: Members

| MemberID (PK) | FullName        | JoinDate   |
|--------------:|-----------------|------------|
| 10            | Sarah Jenkins   | 2026-01-01 |
| 20            | Mark Sloan      | 2026-02-15 |
| 30            | Elena Rodriguez | 2026-03-01 |
| …             | …               | …          |

#### Table 3: Tickets

| TicketID (PK) | CustomerID (FK) | MovieTitle   | Price |
|--------------:|----------------:|--------------|------:|
| 501           | 10              | Inception    | $12   |
| 502           | 10              | The Matrix   | $12   |
| 503           | 40              | Interstellar | $15   |
| …             | …               | …            | …     |

#### 1(c)(i) Join query [6 marks]

Write an SQL query that joins the `Members` and `Tickets` tables.

Your query should display:

- `FullName`
- `MovieTitle`
- `Price`

**Constraint:** You must link the tables using the correct primary key and foreign key.

#### 1(c)(ii) Filter and sort query [4 marks]

Write an SQL query to display the `MovieTitle` and `Price` for all tickets where the price is greater than `10`.

The results must be sorted by `Price` in descending order, with the highest price first.

---

## Question 2: Web Development Principles [30 marks]

### 2.1 Request parameters and paths [10 marks]

A fitness app uses two different ways to find data. Evaluate the following requests:

```http
GET /api/v1/workouts/45
GET /api/v1/workouts?type=running
```

Explain the difference between a **path variable** and a **request parameter** using these two examples.

In which scenario would you use one over the other?

---

### 2.2 The persistence layer [10 marks]

#### 2.2(a) Repository method

Inside a Spring Boot repository, you see the method:

```java
long countByStatus(String status);
```

Explain:

- What this method returns.
- How Spring Data JPA "writes" the code for you based on that method name.

#### 2.2(b) Entity-to-table annotation

Which specific annotation is used to link a Java class to a specific table name in the database?

---

### 2.3 Authentication vs. authorization [10 marks]

In the context of a fitness app where users have **private** and **public** profiles:

#### 2.3(a) Definitions

Define:

- Authentication
- Authorization

#### 2.3(b) Private profile access

If a user tries to view a private profile that does not belong to them, which check has failed?

Provide a logical example of how a Spring Boot service might perform this check.

---

## Question 3: Web Development Practice [40 marks]

### 3.1 JDL modeling: Activities [15 marks]

You are modeling a workout log.

#### 3.1(a) Activity entity

Define a JDL for an `Activity` entity with the following fields:

| Field             | Type    | Requirement |
|------------------|---------|-------------|
| `type`           | String  | Required    |
| `durationMinutes`| Integer | —           |
| `caloriesBurned` | Integer | —           |
| `timestamp`      | Instant | —           |

#### 3.1(b) Field constraint

Ensure `type` is limited to a maximum of 30 characters.

#### 3.1(c) Relationship

Create an appropriate relationship between `Activity` and the built-in `User` entity.

---

### 3.2 CURL and methods [10 marks]

#### 3.2(a) PATCH request

Write a `curl` command to `PATCH` an existing `Activity` with ID `700` to change `durationMinutes` to `45`.

Assume the application is running on:

```text
localhost:8080
```

#### 3.2(b) Incorrect HTTP method

If the developer accidentally uses the `POST` method on:

```http
/api/activities/700
```

what `4xx` error code is most likely to be returned?

Explain why.

---

### 3.3 Versioning and deprecation [15 marks]

The app is moving to a new version to support **GPS coordinates**.

#### 3.3(a) New endpoint structure

How would you structure the `@RequestMapping` for a new `ActivityResource` to distinguish it from the old endpoint?

#### 3.3(b) Support period for old endpoint

If you keep the old endpoint active for 6 months while people migrate:

- What is this period of support called?
- Explain one strategy to notify developers using the old endpoint that they need to switch.
