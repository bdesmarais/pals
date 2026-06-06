# Package Design — `pals`

R package implementing the PALS (Projected Actor Locations) method. Public API,
internal structure, and the R/C++ split. Implements `ALGORITHM.md`.

> **Name note:** there is an unrelated CRAN package `pals` (colour palettes). This
> package is named `pals` per the project brief and targets JOSS (not necessarily
> CRAN); the collision is recorded in `DECISIONS.md` #6.

---

## 1. Data structures

### `pal_events` (S3, subclass of `data.frame`)
Validated dyadic-event table. Columns (canonical names): `actor1`, `actor2`, `time`
(Date), `lon`, `lat`. Constructor `pal_events(data, actor1=, actor2=, time=, lon=,
lat=)` renames/validates, checks lon∈[-180,180], lat∈[-90,90], drops/flags self-dyads,
sorts by time. `print`/`summary` methods report #events, #actors, time span, bbox.

### `pals_params`
Lightweight list with class `pals_params`: `alpha`, `beta`, `gamma`, `eta`, `model`
(`"four"`/`"one"`). Constructor `pals_params(...)`. Used to project without estimating.

### `pals_fit`
Returned by `estimate_pals()`. Fields: `params` (natural scale), `model`, `objective`,
`convergence`, `optim` (raw), `events`, `predict_time`, `call`, settings
(`alter_weight`, `eps_age`, `radius`). Methods: `print`, `summary`, `coef`, `predict`,
`plot`.

### `pals_boot`
Returned by `bootstrap_pals()`. Fields: `replicates` (matrix of param draws), `pals`
(per-replicate projected locations, optional), `R`, `base_fit`. Methods: `print`,
`summary` (param mean/SD/quantiles), `plot`.

---

## 2. Public functions (exported)

Core:
- `pal_events()` — construct/validate event table.
- `pals_params()` — make a parameter set.
- `project_pal(events, actor, predict_time, params, ...)` — one actor, one/many times →
  data frame of `actor, time, lon, lat, n_focal, n_alter, has_history`.
- `project_pals(events, actors=, predict_time=, params=, ...)` — many actors × times.
- `predict_event_locations(events, dyads, predict_time, params, ...)` — per-dyad mean-PAL
  predicted location (+ optional observed + haversine error).
- `estimate_pals(events, fit_events=, model=c("four","one"), predict_time=, ...)` →
  `pals_fit`. Marching-forward objective; `optim`-based.
- `predict(pals_fit, newdata=, predict_time=, type=c("pal","event"))`.

Distances:
- `haversine(lon1, lat1, lon2, lat2, radius=6371.0088)` — vectorized great-circle km
  (Rcpp). Recycles args; the workhorse for objective + covariate building.
- `pal_distance(pals_fit | params, events, dyads, predict_time, transform=c("none","log"))`
  — dyadic PAL distance covariate (with the `log(d + 0.01)` option from the paper).

Uncertainty:
- `bootstrap_pals(events, model=, R=10, fit_events=, predict_time=, seed=, parallel=)` →
  `pals_boot`.
- `pool_rubin(estimates, variances, df=FALSE)` → pooled estimate/variance/SE (+ Barnard–
  Rubin df optionally). Vectorized over multiple estimands.

Helpers / workflow:
- `estimate_pals_yearly(events, years, model=, ...)` — reproduce the marching-forward
  per-year estimation+projection; returns params + PALs by year (a `pals_yearly` object).
- `simulate_conflict_events(n_actors=, n_events=, years=, seed=, ...)` — generate
  Nigeria-like dyadic conflict events (mobile clusters) for examples/tests.

Visualization:
- `plot_pals_map(...)` / `autoplot` — projected vs observed locations on a lon/lat map,
  with segments connecting predicted→observed (ggplot2).
- `plot_param_trajectory(yearly | boot, ...)` — parameter estimates over years/replicates
  with bootstrap CIs (ggplot2).

### Data
- `nigeria_sim` — a saved simulated `pal_events` dataset (~30 actors, 2000–2016) used in
  examples, tests, vignette. Documented via roxygen `@docType data`.

---

## 3. R / C++ split

Compiled (Rcpp, `src/`):
- `haversine_cpp(lon1, lat1, lon2, lat2, radius)` — vectorized.
- `project_one_cpp(focal_age, focal_lon, focal_lat, alter_age, alter_lon, alter_lat,
   alpha, beta, gamma, eta, pi_zero, alter_legacy, eps)` → length-2 `{lon, lat}` (plus
   counts). Pure numeric kernel; all history extraction done in R and passed in.

Pure R:
- history extraction (filter events by actor & `time < t`), orchestration of the
  per-event objective, `optim` wrapper, bootstrap loop, Rubin pooling, plotting, data
  sim, S3 methods, validation. Keeps the compiled surface tiny and the logic readable.

Rcpp wiring: `@useDynLib pals, .registration = TRUE`, `@importFrom Rcpp sourceCpp`,
`compileAttributes()`; `LinkingTo: Rcpp`, `Imports: Rcpp` in DESCRIPTION.

A **pure-R reference** of `project_one` (`project_one_r`, `@noRd`) is kept for testing
the C++ kernel against (equivalence test).

---

## 4. Dependencies (keep light)

- **Imports**: `Rcpp` (LinkingTo+Imports), `stats`, `ggplot2` (plots). Maybe `rlang`
  for tidy eval in `pal_events` column selection.
- **Suggests**: `testthat (>= 3.0)`, `knitr`, `rmarkdown`, `maps`/`rnaturalearth`
  (optional basemap in vignette — guard with `requireNamespace`), `mice` (cross-check
  Rubin pooling in a test, optional), `covr`.
- No hard dependency on `geosphere` (Haversine implemented in C++), `sf`, or `amen`.

---

## 5. Module → file map (`R/`)

- `pals-package.R` — `_PACKAGE` doc, `@useDynLib`, imports.
- `events.R` — `pal_events`, validation, print/summary.
- `params.R` — `pals_params`.
- `project.R` — `project_pal`, `project_pals`, history extraction, `project_one_r`.
- `distance.R` — `haversine`, `pal_distance`, `predict_event_locations`.
- `estimate.R` — `estimate_pals`, objective, `predict.pals_fit`, methods.
- `bootstrap.R` — `bootstrap_pals`, methods.
- `rubin.R` — `pool_rubin`.
- `yearly.R` — `estimate_pals_yearly`, `pals_yearly` methods.
- `simulate.R` — `simulate_conflict_events`.
- `plots.R` — `plot_pals_map`, `plot_param_trajectory`, autoplot.
- `data.R` — dataset docs.
- `RcppExports.R` — generated.

`src/`: `haversine.cpp`, `project.cpp`, `RcppExports.cpp` (generated).
`tests/testthat/`: one file per R module (`test-*.R`).
`vignettes/`: `pals-introduction.Rmd` (full workflow on `nigeria_sim`).
