# Configuration

Create a local configuration from the template:

```powershell
Copy-Item config.example.R config.R
```

## Required settings

| Setting | Example | Meaning |
| --- | --- | --- |
| `PROGRAM_CODE` | `"ELECEX2350"` | Code in the UQ URL |
| `PROGRAM_ROUTE_TYPE` | `"plan"` | `plan` or `program` |
| `ACADEMIC_YEAR` | `2026` | Year segment in the URL |
| `COMPLETED_COURSES` | `c("MATH1051")` | Courses shown as completed |
| `CURRENT_COURSES` | `c("CSSE2310")` | Courses shown as current |
| `REQUEST_DELAY` | `1` | Seconds between course requests |
| `REQUEST_TIMEOUT` | `30` | Seconds before a request fails |

`config.R` is local state. Keep it out of commits when it contains your personal course history.

## Find the code

Open the UQ Programs and Courses site, find your requirements page, and inspect its address. Copy the code and year from either:

```text
https://programs-courses.uq.edu.au/requirements/plan/CODE/YEAR
https://programs-courses.uq.edu.au/requirements/program/CODE/YEAR
```

## Validate settings before scraping

Confirm that the URL opens in a normal browser. A wrong code can produce a page with no rendered course list. The scraper stops with an explanation rather than creating an empty dataset.
