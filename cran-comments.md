## Submission

This is a new submission (palsr 0.1.0).

## Test environments

* local macOS, R 4.6.0
* R-hub / GitHub Actions: Ubuntu, macOS, Windows (release), R-devel and R-release

## R CMD check results

`R CMD check --as-cran` returns 0 ERRORs, 0 WARNINGs, and the following NOTEs:

* "New submission" — expected for a first submission.
* "Files 'README.md' or 'NEWS.md' cannot be checked without 'pandoc' being
  installed." — local environment only; pandoc is available on the CRAN check
  machines.
* HTML manual validation NOTE — local environment only (tidy not installed).

## Notes for CRAN

* The package compiles C++ via Rcpp.
* Examples and tests run on a small bundled simulated dataset and complete quickly.
* The bundled `nigeria_acled` dataset is redistributed from the authors' own public
  replication archive on Harvard Dataverse (\doi{10.7910/DVN/NLWWPE}) for
  Kim, Liu and Desmarais (2023).
