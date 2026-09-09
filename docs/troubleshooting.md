# Troubleshooting

## Chrome or chromote cannot start

Install Google Chrome and make sure it can start normally. `chromote` launches a local headless Chrome session for JavaScript-rendered requirements pages.

## No course codes found

Check `PROGRAM_CODE`, `PROGRAM_ROUTE_TYPE`, and `ACADEMIC_YEAR`. Open the URL in a browser and confirm that the selected year exists.

## Course details are missing

The UQ course page may have changed its field identifiers. Inspect the page, save the HTML as a fixture, and open an issue with the URL and year.

## Manual review items remain

This is expected for free-text rules such as credit totals or prior academic qualifications. Complete the CSV template and rerun the review stage.
