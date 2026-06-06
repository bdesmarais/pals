# R Package Best Practices (CRAN + JOSS Ready, with Rcpp)

Best-practice guidance for building a high-quality R package that includes
C++ (Rcpp) code, targeting both CRAN acceptance and a JOSS submission. The
package implements a statistical method (geospatial smoothing / projection
with bootstrap and optimization). Sources are listed at the end.

The fastest way to scaffold most of this correctly is to let `usethis` and
`devtools` do the boilerplate, then refine by hand. Recommended bootstrap:

```r
# In a fresh dir; pick a CRAN-legal name (letters/numbers/dots, start w/ letter)
usethis::create_package("path/to/pals")
usethis::use_mit_license()            # or another OSI license
usethis::use_roxygen_md()             # markdown in roxygen
usethis::use_package_doc()            # package-level _PACKAGE doc
usethis::use_testthat(3)              # testthat 3e
usethis::use_rcpp()                   # src/, LinkingTo+Imports Rcpp, .gitignore
usethis::use_readme_rmd()             # executable README
usethis::use_news_md()                # NEWS.md changelog
usethis::use_github()                 # populates URL/BugReports
usethis::use_github_action("check-standard")
usethis::use_github_action("test-coverage")
usethis::use_pkgdown_github_pages()
usethis::use_vignette("pals")         # intro vignette (name == pkg => Get Started)
```

---

## 1. Package Structure & Metadata (DESCRIPTION + NAMESPACE)

### DESCRIPTION fields

**Title** — single line, plain text (no markup), title case, no trailing
period, < 65 characters. Put other R package names in single quotes
(`'ggplot2'`). Do NOT start with "A package for…" / "This package…" and do
not include your own package name.

```
Title: Geospatial Smoothing and Projection with Bootstrap Inference
```

**Description** — one paragraph, lines wrapped at ~80 chars with 4-space
continuation indent. Single-quote software names, spell out acronyms, do not
repeat the package name, do not start with "A package for…". Add method
references as `Author (Year) <doi:...>` where applicable (CRAN encourages
this).

```
Description: Implements geospatial smoothing and projection of spatial
    fields, with bootstrap-based uncertainty quantification and parameter
    optimization. Methods follow Author (2024) <doi:10.xxxx/xxxxx>.
```

**Authors@R** — use `person()`. Roles: `aut` (author), `cre`
(maintainer; exactly one, must have an email — CRAN notifies it), `ctb`
(small contributions), `cph` (copyright holder), `fnd` (funder). Add ORCID
via `comment`. Only `aut` show up in the auto-generated citation.

```r
Authors@R: c(
    person("Given", "Family", email = "you@example.com",
           role = c("aut", "cre"),
           comment = c(ORCID = "0000-0000-0000-0000")),
    person("Other", "Person", role = "aut"))
```

**License** — mandatory, machine-readable standard name. MIT via
`usethis::use_mit_license()` writes `License: MIT + file LICENSE`, a
two-line `LICENSE` (year + copyright holder), a full `LICENSE.md`, and
build-ignores `LICENSE.md`.

**Dependency fields**:

| Field | Use | Installed for users? |
|-------|-----|-----------------------|
| `Imports` | Packages your code needs at runtime | Yes |
| `Suggests` | Optional: tests, vignettes, examples | No (check at use site) |
| `LinkingTo` | C/C++ headers needed to *compile* (e.g. Rcpp, RcppArmadillo) | Build-time |
| `Depends` | Avoid (attaches package); only for min R version | Yes |

- One package per line, alphabetical, add with `usethis::use_package("dplyr")`.
- Specify minimum versions where it matters (`dplyr (>= 1.0.0)`); never pin
  exact versions. Justify any `Depends: R (>= 4.x)`.
- For Rcpp: it appears in **both** `LinkingTo` and `Imports` (see §4).

**Other fields**:
```
Encoding: UTF-8
RoxygenNote: 7.3.x          # auto-managed by roxygen2
VignetteBuilder: knitr       # added by use_vignette()
Config/testthat/edition: 3   # added by use_testthat(3)
URL: https://you.github.io/pals, https://github.com/you/pals
BugReports: https://github.com/you/pals/issues
```
`SystemRequirements:` for external/native deps (plain text; does not
install). `Config/Needs/website: pkgdown` for website-only deps.
`usethis::use_github()` fills `URL`/`BugReports`.

### NAMESPACE — never edit by hand

roxygen2 generates `NAMESPACE` from `@export` / `@importFrom` / `@import` /
`@useDynLib` tags. Run `devtools::document()` (Ctrl/Cmd+Shift+D). Resulting
lines look like `export(foo)`, `importFrom(stats, optim)`,
`useDynLib(pals, .registration = TRUE)`.

---

## 2. Documentation (roxygen2)

- Comments start with `#'`; one roxygen block per exported function.
- Every **exported** function needs docs (`@param` for each arg, `@return`,
  a title, and ideally `@examples`). Mark internal helpers with `@noRd` (no
  `.Rd` generated) or `@keywords internal` (generated but hidden from index).
- `@returns` is the modern spelling of `@return`; either works.
- `@export` adds to the public API. `@importFrom pkg fun` / `@import pkg`
  manage imports (prefer `pkg::fun()` in code — see §3).
- `@details`, `@seealso [fun()]`, `@examples`, `@inheritParams pkg::fun`,
  `@family`, `@references` round out a page.

```r
#' Smooth a spatial field
#'
#' Applies geospatial smoothing with optional bootstrap uncertainty.
#'
#' @param x A numeric matrix of observations.
#' @param bandwidth Positive numeric smoothing bandwidth.
#' @param n_boot Integer number of bootstrap replicates.
#' @returns A list with the smoothed field and bootstrap summaries.
#' @seealso [project_field()]
#' @examples
#' m <- matrix(rnorm(100), 10, 10)
#' smooth_field(m, bandwidth = 1)
#' @export
smooth_field <- function(x, bandwidth, n_boot = 0) { ... }
```

### Runnable examples

- Examples are executed by `R CMD check` and must run in < ~10 min with no
  side effects (no file writes outside tempdir, no network).
- `\dontrun{}` — code **never** runs (use only for genuinely unrunnable code:
  needs API keys, interactive input).
- `\donttest{}` — runs under `R CMD check --as-cran` (CRAN executes it),
  skipped by plain `example()`. Use for slow-but-valid examples.
- `@examplesIf condition` — modern, preferred over wrapping in `if`/`\dontrun`
  for conditional (e.g. suggested-package) examples; renders cleanly.
- `try(...)` to show an error without halting.

### Package-level doc

`usethis::use_package_doc()` creates `R/pals-package.R` with the `"_PACKAGE"`
sentinel; roxygen2 then builds the `?pals` help page from DESCRIPTION. This
file is the home for global tags such as `@importFrom` and the Rcpp
`@useDynLib` / `@importFrom Rcpp sourceCpp` directives:

```r
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @useDynLib pals, .registration = TRUE
#' @importFrom Rcpp sourceCpp
## usethis namespace: end
NULL
```

---

## 3. Testing, Coverage, CI

### testthat 3e layout

`usethis::use_testthat(3)`:
- creates `tests/testthat/` + `tests/testthat.R`,
- adds `testthat (>= 3.0.0)` to Suggests,
- sets `Config/testthat/edition: 3`.

Mirror source files: `R/smooth.R` ↔ `tests/testthat/test-smooth.R`. Test
files live in `tests/testthat/`, are named `test-*.R`. Use
`usethis::use_test("smooth")` to create the paired file.

```r
test_that("smoothing preserves dimensions", {
  m <- matrix(rnorm(100), 10, 10)
  out <- smooth_field(m, bandwidth = 1)
  expect_equal(dim(out$field), dim(m))
})

test_that("invalid bandwidth errors", {
  expect_error(smooth_field(matrix(0, 2, 2), bandwidth = -1),
               class = "rlang_error")   # test by class, not regex
})
```

Common expectations: `expect_equal` (tolerance), `expect_identical` (exact),
`expect_error(..., class=)`, `expect_warning`, `expect_match`,
`expect_length`, `expect_s3_class`, `expect_true/false`.

**Snapshot tests** (3e) capture human-readable output in
`tests/testthat/_snaps/<file>.md`:
```r
test_that("print method is stable", {
  expect_snapshot(print(smooth_field(matrix(0, 4, 4), 1)))
})
```

**Skips** for suggested deps / platform issues:
```r
skip_if_not_installed("sf")
skip_on_cran()        # for slow/stochastic tests
```
In tests you may assume Suggests are installed (testthat itself is one).

### Coverage + CI

- Coverage with `covr`: `covr::report()` locally;
  `usethis::use_github_action("test-coverage")` reports to codecov.
- `usethis::use_github_action("check-standard")` — `R-CMD-check.yaml` running
  R-release on Linux/macOS/Windows + R-devel/oldrel on Linux.
- `usethis::use_pkgdown_github_pages()` — builds + deploys the site on push.
- Each helper adds the workflow YAML and a README badge automatically.

---

## 4. Rcpp Integration

### Setup & layout

`usethis::use_rcpp()` creates `src/`, adds `Rcpp` to **both** `LinkingTo`
and `Imports`, gitignores compiled artifacts, and prints the roxygen
namespace tags to paste into the package doc. (For linear algebra, use
`RcppArmadillo` — `LinkingTo: Rcpp, RcppArmadillo` and `Imports: Rcpp`.)

```
DESCRIPTION:
LinkingTo: Rcpp
Imports: Rcpp

src/.gitignore:
*.o
*.so
*.dll
```

### Exporting C++ to R

Mark functions with `// [[Rcpp::export]]`. Run
`Rcpp::compileAttributes()` (or "Build & Reload" / `devtools::document()`),
which scans for the attribute and generates **`src/RcppExports.cpp`** and
**`R/RcppExports.R`**. Never edit those two files by hand.

```cpp
#include <Rcpp.h>
using namespace Rcpp;

//' Bootstrap smoother (C++ core)
//' @param x Numeric matrix.
//' @param bw Bandwidth.
//' @return Numeric matrix.
//' @export
// [[Rcpp::export]]
NumericMatrix smooth_cpp(NumericMatrix x, double bw) {
  // ...
  return x;
}
```
Use `//'` (not `#'`) for roxygen on C++ functions when you want the R
wrapper exported + documented.

### Required namespace directives

In `R/pals-package.R` (see §2):
```r
#' @useDynLib pals, .registration = TRUE
#' @importFrom Rcpp sourceCpp
```
`.registration = TRUE` loads registered native routines.
`@importFrom Rcpp sourceCpp` (any single Rcpp import) is required so the Rcpp
shared lib is available — a known R quirk.

### Runtime / portability tips

- Output with `Rcpp::Rcout`, not `std::cout`.
- Long loops: call `Rcpp::checkUserInterrupt()`.
- Add an unload hook:
  ```r
  .onUnload <- function(libpath) {
    library.dynam.unload("pals", libpath)
  }
  ```
- Usually no `src/Makevars` is needed. Add one only for flags/OpenMP; for
  C++ standard prefer `SystemRequirements: C++17` over hard-coding
  `CXX_STD`. Keep code portable per CRAN "Writing Portable C and C++"
  (avoid `-Wall`/`-pedantic`-tripping constructs).
- To expose C++ headers to other packages add
  `// [[Rcpp::interfaces(r, cpp)]]` (generates `inst/include/pals.h`).

---

## 5. Vignettes & pkgdown

`usethis::use_vignette("pals")` creates `vignettes/pals.Rmd`, adds
`VignetteBuilder: knitr` + `knitr`/`rmarkdown` to Suggests, and gitignores
previews. Naming the intro vignette after the package makes it the pkgdown
"Get Started" page. Required YAML header:

```yaml
---
title: "Introduction to pals"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Introduction to pals}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---
```
- Don't hand-maintain `inst/doc/` — it is generated at `R CMD build`.
- Gate slow/optional chunks: ```` ```{r, eval = requireNamespace("sf")} ````.
- For heavy/CRAN-unfriendly content use `usethis::use_article()` (pkgdown-only,
  not shipped in the tarball — avoids CRAN size/time limits).

**pkgdown**: `usethis::use_pkgdown()` then
`usethis::use_pkgdown_github_pages()` for CI deploy. Set `url:` in
`_pkgdown.yml` (enables auto-linking) and matching `URL:` in DESCRIPTION.
Bootstrap 5 template; organize the reference index with titled sections.

---

## 6. Passing `R CMD check --as-cran` + Community Files

Run before every submission:
```r
devtools::check()                       # local, all platforms-ish
devtools::check(args = "--as-cran")
devtools::check_win_release()           # Windows
rhub::rhub_check()                      # multi-platform
urlchecker::url_check()                 # dead URLs are a NOTE
```
Target: **0 errors, 0 warnings, 0 notes** (a first-submission "new
submission" NOTE is expected and fine). Any other NOTE is a likely rejection.

### Common NOTES/WARNINGS and fixes

- **"no visible binding for global variable"** (from dplyr/ggplot2 NSE):
  use the `.data$col` pronoun (`@importFrom rlang .data`), quote tidyselect
  names, or declare `utils::globalVariables(c("var1","var2"))` in `R/globals.R`.
- **Undefined global functions/variables** (e.g. `optim`, `quantile`): add
  `@importFrom stats optim quantile` so they land in NAMESPACE.
- **Undocumented arguments / mismatched `@param`**: every arg documented,
  names match signature; re-`document()`.
- **Non-standard files / large files at top level**: build-ignore via
  `usethis::use_build_ignore()`.
- **Examples take too long / need network**: wrap in `\donttest{}` or
  `@examplesIf`, add `skip_on_cran()` to slow tests.
- **Spelling**: `usethis::use_spell_check()` / `spelling::spell_check_package()`.
- **License mismatch**: ensure DESCRIPTION `License` matches the LICENSE file.

Include a **`cran-comments.md`** (`usethis::use_cran_comments()`) describing
the submission and check results; CRAN reviewers read it.

### Community / repo files

```r
usethis::use_mit_license()       # LICENSE + LICENSE.md
usethis::use_readme_rmd()        # README.Rmd -> README.md (devtools::build_readme())
usethis::use_news_md()           # NEWS.md changelog (powers pkgdown Changelog)
usethis::use_code_of_conduct("you@example.com")
usethis::use_tidy_contributing() # CONTRIBUTING.md
usethis::use_lifecycle_badge("experimental")
```
README should carry badges (R-CMD-check, codecov, CRAN status, lifecycle)
— the CI helpers add them automatically. Bump `Version` per SemVer; record
user-facing changes in `NEWS.md`.

### JOSS-specific readiness

JOSS expects, beyond CRAN quality:
- OSI license + public, contributable repo (issues/PRs open).
- **> 6 months** of real, iterative public development history (not a dump).
- Automated tests + CI, clear API documentation, installation instructions.
- **Community guidelines**: CONTRIBUTING + CODE_OF_CONDUCT + support channel.
- A **`paper.md`** (Markdown) with: title, authors+affiliations+ORCID, a
  **Summary** (accessible to non-specialists), a **Statement of Need**, a
  brief **State of the Field** (how it compares to existing packages), and a
  **`paper.bib`** with all software/method references. The paper describes the
  software, not new research results. Disclose any generative-AI usage.
- Demonstrable research applicability (substantial scholarly effort, not a
  thin wrapper).

---

## Checklist

Metadata
- [ ] Title: title-case, < 65 chars, no period, no pkg name, single-quoted deps
- [ ] Description: one paragraph, acronyms expanded, method `<doi:...>` cited
- [ ] `Authors@R` with one `cre` (email), `aut`, ORCIDs, `cph`/`fnd` as needed
- [ ] License set via `use_mit_license()`; LICENSE matches DESCRIPTION
- [ ] Imports/Suggests/LinkingTo correct; alphabetized; min versions where needed
- [ ] `Encoding: UTF-8`, `RoxygenNote`, `URL`, `BugReports` present
- [ ] NAMESPACE generated only by roxygen2 (`devtools::document()`)

Docs
- [ ] All exported fns: title, `@param` (all args), `@return`, `@examples`
- [ ] Internal fns `@noRd` / `@keywords internal`
- [ ] Examples runnable & fast; `\donttest{}`/`@examplesIf` where needed
- [ ] `R/pals-package.R` with `"_PACKAGE"` + global imports

Rcpp
- [ ] `LinkingTo: Rcpp` AND `Imports: Rcpp`
- [ ] `@useDynLib pals, .registration = TRUE` + `@importFrom Rcpp sourceCpp`
- [ ] `// [[Rcpp::export]]` used; RcppExports.{cpp,R} auto-generated, not edited
- [ ] `*.o`/`*.so`/`*.dll` gitignored; `.onUnload` hook; portable C++

Testing/CI
- [ ] `use_testthat(3)`, `Config/testthat/edition: 3`
- [ ] Tests mirror `R/`; error tests by class; `skip_on_cran()` for slow/stochastic
- [ ] covr + GitHub Actions: check-standard, test-coverage, pkgdown

Vignettes/site
- [ ] `use_vignette("pals")` with correct YAML; intro vignette named for pkg
- [ ] pkgdown deployed; `url:` set in `_pkgdown.yml` and DESCRIPTION

Release / JOSS
- [ ] `check(--as-cran)`, win, rhub, url_check all clean (0/0/0 + new-submission)
- [ ] README badges, NEWS.md, cran-comments.md
- [ ] CODE_OF_CONDUCT, CONTRIBUTING, support channel
- [ ] paper.md + paper.bib; >6 mo public history; statement of need

---

## Sources

- R Packages (2e), Wickham & Bryan — [DESCRIPTION](https://r-pkgs.org/description.html),
  [Function docs / roxygen2](https://r-pkgs.org/man.html),
  [Testing basics](https://r-pkgs.org/testing-basics.html),
  [Dependencies in practice](https://r-pkgs.org/dependencies-in-practice.html),
  [Vignettes](https://r-pkgs.org/vignettes.html),
  [Whole game](https://r-pkgs.org/whole-game.html)
- R Packages (1e mirror), [Compiled code chapter](https://bookdown.dongzhuoer.com/hadley/r-pkgs/src)
- usethis — [use_package_doc()](https://usethis.r-lib.org/reference/use_package_doc.html),
  [GitHub Actions](https://usethis.r-lib.org/reference/github_actions.html),
  [use_github_action()](https://usethis.r-lib.org/reference/use_github_action.html)
- Rcpp — [CRAN Rcpp manual](https://rcppcore.r-universe.dev/Rcpp/doc/manual.html),
  [Using Rcpp in an R package (Fasiolo SC2)](https://mfasiolo.github.io/sc2-2019/rcpp_advanced_ii/2_rcpp_in_packages/),
  [Advanced R: Rcpp in a package](https://bookdown.dongzhuoer.com/hadley/adv-r/rcpp-package)
- pkgdown — [Get started](https://pkgdown.r-lib.org/articles/pkgdown.html)
- CRAN checks — [dplyr: using in packages (.data pronoun)](https://cran.r-project.org/web/packages/dplyr/vignettes/in-packages.html),
  ["no visible binding" fixes](https://caoyang.tech/post/r-packages-how-to-solve-the-check-note-no-visible-binding-for-global-variable/),
  [Passing CRAN checks (Mastering Software Dev in R)](https://bookdown.org/rdpeng/RProgDA/passing-cran-checks.html),
  [CRAN submission tutorial](https://rguides.dev/tutorials/r-package-development/cran-submission/)
- JOSS — [Submitting](https://joss.readthedocs.io/en/latest/submitting.html),
  [Review checklist](https://joss.readthedocs.io/en/latest/review_checklist.html)
