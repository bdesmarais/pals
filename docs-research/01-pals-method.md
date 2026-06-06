# PALS (Projected Actor Locations) — Method Research Notes

Research notes to guide a from-scratch R implementation of the PALS method.
Compiled from the published article **and the authors' actual replication R code**
(Harvard Dataverse). Where the published equations and the released code disagree,
both are recorded and the discrepancy is flagged. **The released code is the
authoritative reference for replicating the published results.**

---

## 1. Bibliographic anchor

- **Article:** Sangyeon Kim, Howard Liu, and Bruce A. Desmarais. "Spatial modeling of
  dyadic geopolitical interactions between moving actors." *Political Science Research
  and Methods*, Vol. 11, Issue 3, July 2023, pp. 633–644.
  - DOI: `10.1017/psrm.2022.6` (Open Access, CC-BY 4.0).
  - Published online 30 March 2022 (received 15 Dec 2020; revised 22 June 2021;
    accepted 20 Oct 2021). It is a **Research Note**.
  - NOTE: the task brief attributes the paper to "Bruce A. Desmarais" alone; the
    actual author order is **Kim, Liu, Desmarais**. Corresponding author Sangyeon Kim
    (szk922@psu.edu).
- **Replication materials (code + data):** Harvard Dataverse, `doi:10.7910/DVN/NLWWPE`.
  This is the primary code reference for the algorithm. (No standalone GitHub PALS
  repo was found; the released code is only on Dataverse.)
- **Underlying study being replicated:** Cassy Dorff, Max Gallop, and Shahryar Minhas,
  "Networks of Violence: Predicting Conflict in Nigeria," *The Journal of Politics*,
  Vol. 82, No. 2, 2020, pp. 476–493. (The article text and one citation say "Dorff and
  Gallop (2020)"; the reference list and the JOP record are Dorff, Gallop & Minhas 2020.)
- **Network model used (AMEN):** Shahryar Minhas, Peter D. Hoff, Michael D. Ward,
  "Inferential Approaches for Network Analysis: AMEN for Latent Factor Models,"
  *Political Analysis*, Vol. 27, No. 2, 2019, pp. 208–222. R package `amen`
  (the replication uses `s7minhas/amen`, git ref `pa2018_version`).
- **Data source:** ACLED (Armed Conflict Location & Event Data), Nigeria, 2000–2016.
  The PALS fitting/training data starts earlier (events back to ~1997–1998 are used to
  produce projections for 1999+; the modeling sample is restricted to years 2000–2016).

---

## 2. Conceptual overview

PALS produces, for each **actor** and each prediction time `t`, a single predicted
2-D coordinate (latitude, longitude) — the location at which that actor is *likely to
engage in a (dyadic) interaction* in the near future. PALs are **interaction
locations**, NOT headquarters / home bases. Most actors can occupy multiple locations
at once, so PALS smooths their event history into one projected point.

The projection blends two histories via a logistic mixing weight:

1. **Focal history** — the locations of past events the focal actor `i` was involved
   in, with recent events up-weighted (time-decay parameter `alpha`).
2. **Alter history** — the locations of past events involving any actor `k` that has
   ever been an opponent ("alter"/"partner") of the focal actor, again time-decayed
   (parameter `beta`).

The method is described as a special case of **exponential smoothing** for time series
(cf. Chatfield et al. 2001, Eq. 3; De Livera et al. 2011).

Two variants:
- **Four-parameter (full) model:** estimates `gamma, eta, alpha, beta`; mixes focal +
  alter histories.
- **One-parameter (alpha-only / focal-only) model:** fixes `pi = 0` (equivalently
  `gamma -> -infinity`), dropping the alter term entirely. Only `alpha` is active and
  estimated. The function becomes effectively monadic.

Empirically the two variants give nearly identical projections and predictive
performance; the paper keeps both for robustness.

---

## 3. Parameters

All four govern how event histories are weighted and combined.

| Param | Domain | Role |
|-------|--------|------|
| `alpha` (α) | ≥ 0 | Time-decay of the **focal** actor's own event history. Larger α ⇒ older events get *less* weight (faster decay). |
| `beta` (β) | ≥ 0 | Time-decay of the **alters'** event histories. Larger β ⇒ faster decay of old alter events. |
| `gamma` (γ) | ℝ | Intercept of the logistic mixing weight `pi`. Higher γ ⇒ more weight on alters' averages. (Paper says "higher γ ⇒ greater weight on alters.") |
| `eta` (η) | ℝ | Slope of the logistic mixing weight on the "relevance"/event-count ratio. Controls how strongly the focal-vs-alter mix depends on the relative number of events in each history. |

**Empirical estimates (Nigeria application):**
- `alpha` ≫ `beta` in almost every year (focal recency matters far more than alter recency).
- On the unit/exp scale `alpha ≈ 0.9` for most years after the first couple.
  Interpretation given in the paper: an event 2 years old is weighted at ~0.53 the rate
  of a 1-year-old event; 4 years old ⇒ ~0.29.
- `gamma` and `eta` are consistently **negative** ⇒ alters' locations contribute little,
  and their influence shrinks as the focal actor accumulates its own history.
- Substantial across-bootstrap variation in all parameters ⇒ uncertainty propagation matters.

### CRITICAL implementation detail — log-scale parameterization
In the released code, `alpha` and `beta` are stored/optimized on the **log scale** and
exponentiated before use:

```
alpha <- exp(<optimized value>)   # ensures alpha > 0
beta  <- exp(<optimized value>)   # ensures beta  > 0
```

`gamma` and `eta` are used **directly** (no transform). So the optimizer searches over
`(gamma, eta, log_alpha, log_beta)`. Start values used in the code:
- Four-parameter yearly projection: `startValue = c(-10, -10, -0.5, -5)`
  = `(gamma, eta, log_alpha, log_beta)`.
- Four-parameter resample/bootstrap variant: `startValue = c(-10, -10, 2, -5)`.
- One-parameter (alpha-only): `startValue = 0.5` (a single `log_alpha`).

The very negative `gamma, eta` start values push `pi` toward 0 (focal-dominated) at the
start of the search.

---

## 4. The core equations

### 4.1 As printed in the article

(Reconstructed; the published PDF rendered one exponent expression as OCR garbage —
see §4.3 for the code-confirmed form. Notation: `a(e)` = age of event `e`,
`g(e)` = location of event `e`, `E_i^(t-)` = events involving focal `i` before `t`,
`E_k^(t-)` = events involving all of `i`'s alters before `t`.)

Focal event weights (unnormalized, then normalized):
```
w_i(e)  = 1 / ( a(e)^alpha + 0.01 )
W_i(e)  = w_i(e) / sum_{r in E_i^(t-)} w_i(r)
```

Alter event weights:
```
w_k(e)  = 1 / ( a(e)^beta + 0.01 )
W_k(e)  = w_k(e) / sum_{r in E_k^(t-)} w_k(r)
```

Relevance / event-count ratio `v` (printed form garbled; code form in §4.3):
```
v = ( |E_i^(t-)| / |E_k^(t-)| ) ^ ( 1 / sqrt( |E_k^(t-)| ) )
```

Logistic mixing weight:
```
pi = 1 / ( 1 + exp( -(gamma + eta * v) ) )    # = plogis(gamma + eta * v)
```

Projected location (applied separately to latitude and longitude):
```
g_i^(t) = (1 - pi) * sum_{e in E_i^(t-)} W_i(e) * g(e)
        +      pi  * sum_{e in E_k^(t-)} W_k(e) * g(e)
```

### 4.2 The `0.01` offset
Inside every weight, the age is raised to a power and then `+ 0.01` is added in the
denominator: `1 / (age^power + 0.01)`. This is a numerical guard so that an event with
**age 0** (e.g., same prediction date) does not produce a divide-by-zero / infinite
weight; with the offset its weight is capped at `1/0.01 = 100`. Keep this exactly.

### 4.3 As implemented in the released R code (AUTHORITATIVE)

From `optim_distm_4para_yearlyProjection.R`,
`optim_distm_alpha_yearlyProjection.R`, the per-year `optim_end<YEAR>fit.R` files, and
the resample variants — the inner computation is byte-for-byte:

```r
gamma <- gamma_eta_alpha_beta[1]
eta   <- gamma_eta_alpha_beta[2]
alpha <- exp(gamma_eta_alpha_beta[3])
beta  <- exp(gamma_eta_alpha_beta[4])

focal_ages <- as.numeric(focal_ages)   # ages in DAYS
alter_ages <- as.numeric(alter_ages)

weights_i <- 1/(focal_ages^alpha + .01)
weights_i <- weights_i/sum(weights_i)      # focal weights ARE normalized

weights_k <- 1/(alter_ages^beta + .01)
weights_k <- 1/(sum(weights_k))            # <-- SEE WARNING BELOW

a <- length(focal_ages)    # number of focal events
e <- length(alter_ages)    # number of alter events
relev <- (a/e)^(1/sqrt(e))

pi <- plogis(gamma + eta*relev)
# pi = 0   # (alpha-only model forces this line ON)

projected_focal_x <- (1-pi)*sum(weights_i*focal_location_history_x) +
                          pi*sum(alter_history_x*weights_k)
projected_focal_y <- (1-pi)*sum(weights_i*focal_location_history_y) +
                          pi*sum(alter_history_y*weights_k)
```

**Key facts confirmed by code:**
1. **Age unit = DAYS.** `ages = predict_date - EVENT_DATE`, in days. The prediction date
   is fixed at **December 1 of the target year** (`as.Date(paste0(year,"-12-01"))`).
   So the smoothing operates on a daily timescale, not yearly. (Important: an event
   from earlier the same year still has age ≈ tens/hundreds of days, not 0.)
2. **`relev` (= published `v`) uses event COUNTS**, where `a = length(focal_ages)` =
   number of focal events, `e = length(alter_ages)` = number of alter events:
   `relev = (a/e)^(1/sqrt(e))`. This is the `v` in `plogis(gamma + eta*v)`. The
   published `v` formula is the garbled version of this.
3. **`pi` in the alpha-only model is hard-set to 0** *after* being computed
   (`pi = 0`), making it purely focal. In the four-parameter model that line is
   commented out.

> ### ⚠️ WARNING — likely bug in the released alter-weight code
> The line `weights_k <- 1/(sum(weights_k))` **overwrites the entire alter-weight
> vector with a single scalar** (the reciprocal of the sum of the unnormalized alter
> weights). It does NOT normalize per-event the way the published `W_k(e)` equation
> says. Consequently the alter contribution actually computed is:
> ```
> pi * sum(alter_history * weights_k)
>    = pi * (sum of alter coordinates) * ( 1 / sum_r 1/(age_r^beta + .01) )
> ```
> i.e. an *un-normalized sum of alter coordinates* scaled by one scalar — not a proper
> weighted average. This differs from the paper's `W_k(e)` (which divides each event
> weight by the sum). Because the estimated `pi` is tiny (γ, η strongly negative), the
> alter term contributes almost nothing, so this bug has negligible effect on published
> results — which is consistent with the paper's finding that focal-only and full
> models are "virtually equivalent."
>
> **Implementation decision needed:** decide whether the R package reproduces the
> code's behavior (`weights_k` as a scalar, for exact replication) or implements the
> *intended* equation `W_k(e) = w_k(e)/sum w_k(r)` (a true weighted average). Recommend:
> implement the correct normalized form as default, but provide a `legacy = TRUE`
> option that reproduces the Dataverse code exactly. The focal weights ARE correctly
> normalized in both code and paper.

### 4.4 Focal-vs-alter projection and the dyadic "event" location
- A PAL is computed **per actor**. For a dyadic event between actors A and B, the
  predicted **event location** used for fitting/evaluation is the **simple arithmetic
  mean of the two actors' PALs**:
  ```r
  lat.pred.xy  = rowMeans(c(lat.pred.A,  lat.pred.B))
  long.pred.xy = rowMeans(c(long.pred.A, long.pred.B))
  ```
  In the optimizer the join is `na.rm=TRUE` (if one actor has no PAL, the event
  location falls back to the other actor's PAL). In the yearly-projection scripts the
  rowMeans has no `na.rm`, so a missing partner PAL yields `NA`.

---

## 5. Parameter estimation

### 5.1 Objective function
Estimate parameters by **minimizing the sum / mean of Haversine (great-circle) arc
distances** between predicted and observed event locations. In code the objective
returns `mean(events$distance/1000, na.rm=TRUE)` — i.e. **mean Haversine distance in
kilometers**. (Paper says "sum of distances"; code minimizes the mean — equivalent up
to a constant for a fixed sample.)

- Distance uses `geosphere::distm(c(lon,lat), c(lon,lat), fun = distHaversine)`, output
  in meters, divided by 1000 ⇒ km. **Order matters: longitude first, then latitude.**
- The predicted location for each event is the **mean of the two actors' PALs** (§4.4).
- Events with `NA` predicted location are dropped (`na.omit`) before averaging.

### 5.2 Optimizer ("hill-climbing")
The paper calls it a "hill-climbing algorithm." The code uses
`optimParallel::optimParallel(par=startValue, fn=..., method="L-BFGS-B",
lower=-Inf, upper=Inf)` — i.e. **L-BFGS-B**, run in parallel across a 16-core cluster.
For the R package, any robust unconstrained/box-constrained optimizer over
`(gamma, eta, log_alpha, log_beta)` (or just `log_alpha` for the 1-param model) should
reproduce results; the log parameterization keeps `alpha, beta > 0` without explicit
bounds.

### 5.3 Marching-forward / temporal training
Parameters used to project locations at time `t` are estimated **only on event data
strictly preceding `t`**. Concretely:
- For yearly projections (`years = 1999:2016`), the parameters for target year `t` come
  from a fit file `optim_end<t-1>fit.R` that uses all events through year `t-1`.
- Inside the objective, for each event the historical set `acled_t` is further
  restricted to `YEAR < year(focal_time)` (strictly earlier years), so the projection
  for an event never sees same-year or future events. This is a genuine out-of-sample
  ("marching forward") setup.
- Actors: the analysis is restricted to the **37 armed groups** that Dorff/Gallop/Minhas
  retain (groups engaged in battles for ≥ 5 years over 2000–2016).

### 5.4 Edge cases observed in code
- **First appearance / no history:** if a focal actor has no prior events, the weighted
  sum is over an empty/zero vector and yields `0`; the code then maps predicted `0` to
  `NA` (`actor_year_df$lat.pred[... == 0] <- NA`). Also `NaN` results are set to `NA`.
  Implementation must treat "no history" as "no PAL" (NA), not as coordinate (0,0).
- **Zero alters:** if `partners` is empty, `alter_ages` is empty, `e = 0`, and
  `relev = (a/0)^(1/sqrt(0))` is `NaN`/`Inf`; `pi` then becomes `NaN`. In practice this
  only matters for the four-parameter model and only when an actor has events but no
  recorded partners — rare in this data, but the package must guard it (e.g., fall back
  to `pi = 0` / focal-only when `e == 0`).
- **Ties / duplicate events:** bootstrap resampling deliberately creates duplicate rows;
  the algorithm handles them as ordinary repeated events (no de-duplication).

---

## 6. Uncertainty: bootstrap + multiple imputation (Rubin's Rules)

### 6.1 Nonparametric bootstrap of events
To propagate PAL uncertainty into the downstream model, the authors:
1. Take a **full random sample with replacement of all events** (`acled[sample(1:nrow,
   replace=TRUE), ]`), producing duplicated rows.
2. Re-run the entire PAL estimation + projection on that resample.
3. Repeat for **10** bootstrap draws. The released code uses fixed seeds:
   `seedNum = c(1112, 1113, 1114, 1115, 1116, 1117, 1120, 1122, 1126, 1128)`
   (one `set.seed()` per draw; the single-draw optimizer files use `set.seed(1120)`).
This is "nonparametric bootstrap prediction" (Fushiki et al. 2005).

### 6.2 Multiple imputation framing
Each bootstrap draw of PALs is treated as **one random imputation** of the latent PAL
covariate. 10 imputations (`m = 10`), consistent with the 5–20 commonly used. The AMEN
model is fit **10 separate times**, once per imputed PAL set.

### 6.3 Rubin's Rules pooling (as implemented)
Because AMEN is Bayesian, the **posterior mean** of each coefficient is treated as the
point estimate and the **posterior SD** as the "standard error" within each imputation.
Pooling across `m = 10` imputations (code in `table1_repl.R`):

For coefficient `i`:
- **Pooled mean:** `pmean[i] = (1/m) * sum_j mean(BETA_j[, i])`
  (mean of the per-imputation posterior means).
- **Within-imputation variance:** `vw[i] = (1/m) * sum_j (psd_j[i])^2`
  where `psd_j[i] = sd(BETA_j[, i])` is the posterior SD in imputation `j`.
- **Between-imputation variance:** `vb[i] = (1/(m-1)) * sum_j (mean(BETA_j[,i]) - pmean[i])^2`
  (note denominator `m - 1 = 9`).
- **Total variance:** `vt[i] = vw[i] + vb[i] + vb[i]/m`
  i.e. `vw + vb*(1 + 1/m)` with `m = 10`.
- **Pooled SE:** `psd[i] = sqrt(vt[i])`.

This is standard Rubin (1987) pooling: `T = W + (1 + 1/m) B`. The reported Table 1
"standard errors" are these pooled posterior SDs; stars are presumably from
`pmean / psd` ratios. (The code does **not** apply Rubin's Barnard–Rubin degrees of
freedom correction; it uses the simple normal-based pooled SE.)

---

## 7. Using PAL distances in the dyadic conflict model (AMEN)

### 7.1 The outcome model
- Outcome `Y`: yearly binary dyadic indicator of whether two armed groups were in
  conflict, 2000–2016 (a directed-but-effectively-symmetric `n x n x T` array; the
  replication runs `symmetric=FALSE`).
- Model: **AMEN** (`amen::ame_repL`), a latent-factor network model with a probit/binary
  link (`model='bin'`), random sender/receiver effects (`rvar=TRUE, cvar=TRUE`),
  multiplicative latent factors `R=2`, intercept, fit by MCMC.
- MCMC settings in the replication: `burn=10000, nscan=10,000,000, odens=25,
  seed=6886`. (Paper: 10,000,000 iterations, vs Dorff/Gallop/Minhas's original 50,000,
  to address mild non-convergence.)
- Baseline covariates retained from the original study:
  - **Dyadic** (`Xdyad`): `govActor` (Gov–Gov dyad), `postBoko` (post-Boko-Haram period),
    `elecYear`, `ngbrConfCount` (neighborhood conflict count).
  - **Sender & receiver node covariates** (`Xrow`, `Xcol`): `riotsProtestsAgainst`,
    `vioCivEvents` (violent events against civilians), `groupSpread` (geographic spread).

### 7.2 Building the PAL-distance covariate
For each year `t` and each dyad `(i, j)` of active nodes:
1. Compute the **Haversine distance between the two actors' PALs**
   (`distm(c(lon_i,lat_i), c(lon_j,lat_j), fun=distHaversine)`), in meters, forming a
   per-year `geodist_mat` and stacking into a list over years.
2. **Two covariate specifications are tested:**
   - **Linear:** raw Haversine distance `preddist_mat`.
   - **Log:** `preddist_log = log(distance + 0.01)` — note the **same 0.01 offset**
     reused to avoid `log(0)`. The log specification is "more common in interstate
     conflict" and gives slightly better out-of-sample fit.
3. The chosen distance matrix is `abind`-ed onto `Xdyad` as one extra dyadic covariate
   slice, and AMEN is re-fit.

### 7.3 Missing-PAL imputation inside the design matrix
Some dyads at time `t` have a missing PAL distance (an actor with no usable history).
The code imputes these via a simple within-sample regression rather than dropping them:
- Build a dyadic indicator `n_no_events[i,j]` = whether one actor in the dyad had **no
  event history** up to that year (count of "null" presence).
- Regress observed `geodist` on this no-history indicator (`lm(y_impute ~ x_impute)`)
  pooling years `2..i`, then fill missing distances with the fitted value
  `intercept + slope * n_no_events`. This produces `geomats_full_hist`.
- This is a *separate* imputation from the bootstrap/MI of §6 — it patches missing
  dyad-distances **within** each design array before the AMEN fit.

### 7.4 Substantive result
- PAL distance has a **statistically significant negative** effect on conflict
  probability in all four extended specifications (linear & log × 1-param & 4-param).
  Closer projected locations ⇒ more likely conflict.
- Linear coefficient ≈ `-1.6e-6` (distance in meters); log coefficient ≈ `-0.15`.
- Predicted probability of conflict drops ~tenfold from 0–100 km (~0.01–0.02) to
  ≥ 500 km (≤ 0.001); under the log spec it falls from ~0.01 to ~0.001 within ~200 km.
- Signs/significance of other covariates are unchanged by adding PAL distance, but the
  geographic-spread coefficients shift the most in magnitude.

---

## 8. Predictive-performance evaluation

- **Two layers of evaluation.**
  1. **PAL accuracy itself** (Figs 2–4): mean Haversine distance between forecast PAL
     event-location and observed event location, by year; map edges from predicted to
     observed locations; and boxplots comparing (a) distances between *observed* events
     in a year vs (b) distances between observed events and *their predicted* locations.
     PAL-to-observed distances are smaller than observed-to-observed distances in all
     but 2 years (2001, 2006 — years where groups fought in new regions, i.e. low
     spatial autocorrelation).
  2. **Downstream model fit** (Fig 6): out-of-sample prediction of dyadic conflict.
- **Cross-validation:** data split into **30 groups/folds**; each fold iteratively held
  out and predicted (`row*_fold01..30.R`, aggregated by `row*_agg.R`). This mirrors
  Dorff/Gallop/Minhas's out-of-sample protocol; the original analysis was also re-run
  at 10,000,000 iterations for comparability.
- **Metrics:** **ROC curves (AUC-ROC)** and **Precision-Recall curves (AUC-PR)**. Because
  conflict events are rare, **AUC-PR is the more informative metric** (cf. Cranmer &
  Desmarais 2017). Helper code in `binPerfHelpers.R`.
- **Finding:** adding PAL distance improves both AUC-ROC and AUC-PR in all four extended
  variants (modest gains). Best out-of-sample model = **four-parameter PALs with the log
  distance specification**. Improvements are small but consistent — "at the very least,
  not over-fitting."

---

## 9. Replication-package file map (Dataverse `10.7910/DVN/NLWWPE`)

Useful files for implementation (download via
`https://dataverse.harvard.edu/api/access/datafile/<id>`):

- `optim_distm_4para_yearlyProjection.R` — four-parameter projection loop (core algorithm).
- `optim_distm_alpha_yearlyProjection.R` — one-parameter (alpha-only) projection loop.
- `optim_distm_4para_resample_yearlyProjection.R`,
  `optim_distm_alpha_resample_yearlyProjection.R` — bootstrap (10-seed) versions.
- `optim_end<YEAR>fit.R` (many copies, per year and per bootstrap dir) — the objective
  function + `optimParallel` call (parameter estimation).
- `table1_data_generation_4para.R`, `table1_data_generation_alpha.R` — build PAL-distance
  dyadic covariate (linear + log), missing-distance imputation, assemble AMEN design arrays.
- `table1_col1.R`, `table1_col2.R` — baseline AMEN fits (`ame_repL`).
- `table1_repl.R` — Rubin's-Rules pooling across 10 imputations; builds Table 1.
- `binPerfHelpers.R` — ROC/PR helpers; `row*_fold*.R`, `row*_agg.R` — 30-fold CV for Fig 6.
- `setup.R`, `actorInfo.R`, `mapData_processing.R` — utilities, actor-name cleaning,
  list→array conversion (`listToArray`).
- `figure1..8_repl.R` — figure reproduction.
- Data objects: `data/optim.rda` (ACLED events `acled` + `actors_list`),
  `nigeriaMatList_acled_v7.rda` (`yList` outcome), `exoVars.rda`
  (`xNodeL`, `xDyadL` covariates) — these originate from Minhas's `conflictEvolution`
  repo (`s7minhas/conflictEvolution`).

Environment pinned by the authors: **R 3.6.3**, `tidyverse` 1.3.0, `dplyr` 1.0.0,
`geosphere` 1.5-10, `optimParallel` 0.8-1, and `amen` at git ref `pa2018_version`
(installed via `devtools::install_github('s7minhas/amen', ref='pa2018_version')`).

---

## 10. Open questions / ambiguities for implementation

1. **Alter-weight normalization (the big one).** Code computes
   `weights_k <- 1/(sum(weights_k))` (a scalar), NOT the per-event normalized
   `W_k(e) = w_k(e)/sum w_k(r)` from the paper (§4.3 warning). Decide: replicate the
   code (legacy, for exact reproduction) vs implement the intended weighted average
   (correct). Recommend a `legacy`/`alter_weight = c("normalized","raw_sum")` switch.
2. **Sum vs mean objective.** Paper says "sum of distances"; code minimizes
   `mean(distance, na.rm=TRUE)` in km. These are not identical when the number of
   non-NA events varies across parameter values (NA events are dropped). Decide which.
3. **`relev` when `e == 0` (zero alters).** Yields `NaN`/`Inf` ⇒ `pi = NaN`. Need a
   defined fallback (recommend `pi <- 0`, focal-only) — the code does not guard this.
4. **Age units.** Code uses **days** with a **Dec-1** prediction date. Any
   re-implementation must fix the prediction-date convention and decay timescale, or
   `alpha`/`beta` estimates won't be comparable. Should the package expose the
   prediction-date offset as a parameter?
5. **`pi` direction of `gamma`.** Code: `pi = plogis(gamma + eta*relev)`, and `pi` is the
   weight on **alters** (`(1-pi)` on focal). Paper text "higher γ ⇒ greater weight on
   alters" matches this. Confirm sign conventions in docs to avoid inversion.
6. **The `0.01` offset is reused in two places**: inside every age weight
   (`age^power + 0.01`) and inside the log distance covariate (`log(distance + 0.01)`).
   Keep both; consider exposing as a constant.
7. **`g(t)` self-prediction quirk.** When a focal actor is its own alter is impossible,
   but alter histories can include events the focal also attended (shared dyadic
   events appear under both actors). No de-duplication is done; decide whether to
   de-duplicate shared events across focal/alter sets.
8. **Predicted-`0` ⇒ `NA` mapping.** Code maps an exactly-zero predicted coordinate to
   `NA` to catch "no history." A legitimate coordinate of exactly 0.0 (equator/prime
   meridian) would be wrongly nulled — irrelevant for Nigeria, but a package should use
   an explicit "had history" flag instead.
9. **Rubin pooling details.** Code uses `T = W + B + B/m` (= `W + (1+1/m)B`) with no
   Barnard–Rubin df and no t-based intervals; significance stars come from
   `mean/SE`. Decide whether the package's pooling helper follows this exactly or uses
   a more complete Rubin implementation (e.g. via `mice::pool`).
10. **Missing-distance imputation (regression on no-history indicator)** is bespoke
    (§7.3) and separate from the bootstrap MI. A general package may want to either
    expose this or replace it with a documented default (e.g. max observed distance, or
    leaving NA for AMEN to handle).
11. **"Number of events" for `relev`.** `a = length(focal_ages)`, `e = length(alter_ages)`
    — alter count is the **total events across all partners** (with multiplicity), not
    the number of distinct partners. Confirm this is the intended `|E_k^(t-)|`.

---

## 11. Sources

Primary article and metadata:
- Cambridge Core article page: https://www.cambridge.org/core/journals/political-science-research-and-methods/article/spatial-modeling-of-dyadic-geopolitical-interactions-between-moving-actors/9D4F222413B90228EBFC78D61DB70287
- DOI: https://doi.org/10.1017/psrm.2022.6
- Open-access full-text PDF (Essex repository): https://repository.essex.ac.uk/32243/1/div-class-title-spatial-modeling-of-dyadic-geopolitical-interactions-between-moving-actors-div.pdf
- Essex repository record: https://repository.essex.ac.uk/32243/
- Penn State Pure record: https://pure.psu.edu/en/publications/spatial-modeling-of-dyadic-geopolitical-interactions-between-movi/
- Howard Liu's page: https://howardhliu.com/publication/moving-objects/
- Sangyeon Kim research page: https://clearingkim.github.io/research/
- Bruce Desmarais lab/site: https://brucedesmarais.com/lab.html
- Plain-language summary (Phys.org): https://phys.org/news/2022-08-spatial-network-path-political-hotspots.html

Replication code & data (authoritative for the algorithm):
- Harvard Dataverse dataset: https://doi.org/10.7910/DVN/NLWWPE
  (resolves to https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/NLWWPE )
- Dataverse API (file listing): https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId=doi:10.7910/DVN/NLWWPE
- Individual file download pattern: https://dataverse.harvard.edu/api/access/datafile/<id>

Underlying / related works:
- Dorff, Gallop & Minhas (2020), "Networks of Violence: Predicting Conflict in Nigeria,"
  *Journal of Politics* 82(2): 476–493 — https://www.journals.uchicago.edu/doi/abs/10.1086/706459
  (Strathclyde OA copy: https://strathprints.strath.ac.uk/66202/)
- Minhas, Hoff & Ward (2019), "Inferential Approaches for Network Analysis: AMEN for
  Latent Factor Models," *Political Analysis* 27(2): 208–222 —
  https://www.cambridge.org/core/journals/political-analysis/article/abs/inferential-approaches-for-network-analysis-amen-for-latent-factor-models/C5766B1FC01B5C875500B5724F162889
  (arXiv: https://arxiv.org/pdf/1611.00460 )
- `amen` R package replication note in code: `s7minhas/amen` (ref `pa2018_version`);
  data from `s7minhas/conflictEvolution`.

> No standalone GitHub repository implementing PALS was located (searched github.com/bdesmarais,
> desmarais-lab, PennState orgs, and the authors' personal sites). The only released code is
> the Dataverse archive above.

---

*Notes compiled 2026-06-06. The Dataverse R scripts are the ground truth; the published
equations contain at least one OCR-garbled formula (the `v`/`relev` exponent) and the
released code's alter-weight normalization diverges from the printed `W_k(e)`. Implement
against the code, document the divergence, and provide a corrected option.*
