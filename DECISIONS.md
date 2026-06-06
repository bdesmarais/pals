# Design Decisions & Rationale

Numbered decisions, each with the question, the choice, and why. Referenced from
`ALGORITHM.md` and `DESIGN.md`.

1. **Alter-weight normalization.** The Dataverse code overwrites the alter weight vector
   with a scalar (`weights_k <- 1/sum(weights_k)`), computing an un-normalized sum of
   alter coordinates rather than the paper's weighted average `W_k(e)=w_k/Σw_k`.
   → **Implement the normalized weighted average as the default** (`alter_weight =
   "normalized"`); provide `alter_weight = "legacy"` for byte-exact reproduction.
   *Why:* the normalized form is what the paper's equations specify and is statistically
   correct; estimated `pi≈0` in the application makes the two numerically equivalent
   there, so we lose nothing and gain correctness + an explicit replication switch.

2. **Objective: mean vs sum of distances.** Paper says "sum"; code minimizes the mean km.
   → **Default `aggregate = "mean"` (km)**, `"sum"` available. *Why:* matches released
   code and is scale-stable when the count of non-NA events varies across parameters.

3. **Optimizer.** Source used `optimParallel` L-BFGS-B across 16 cores ("hill-climbing").
   → **Use base `stats::optim`** (Nelder–Mead for 4-param, Brent for 1-param) with a
   `method` override and optional restarts. *Why:* zero extra dependencies, reproducible,
   adequate for the low-dimensional smooth objective; users can pass `method="L-BFGS-B"`.

4. **Positivity of alpha/beta.** → Optimize on **log scale** (`alpha=exp(.)`), exactly as
   the source code, so no box constraints are needed and estimates match.

5. **Prediction date.** Source fixes Dec-1 of the target year. → **Expose `predict_time`
   as a free argument**; provide `estimate_pals_yearly()` that reproduces the Dec-1
   marching-forward convention. *Why:* generality without losing replicability.

6. **Package name collision.** CRAN has an unrelated `pals` (colour palettes). → **Keep
   `pals`** per the project brief; JOSS does not require CRAN. Documented prominently.
   If CRAN submission is later desired, rename (e.g. `palsr`) is a one-shot change.
   *Why:* honor the brief; flag the constraint rather than silently renaming.

7. **Age units / timescale.** → **Days**, as in source. Internally `as.numeric(t - time)`
   on Dates. `alpha/beta` are therefore on a per-day decay scale (document the
   interpretation, incl. the paper's "2-yr event ≈ 0.53× a 1-yr event" example).

8. **Zero-alter fallback.** `v=(n_i/0)^…` is undefined. → When `n_k==0`, set `pi=0`
   (focal-only) and warn at most once. *Why:* avoids `NaN` PALs; the only sensible blend.

9. **No-history → NA, not (0,0).** → Track a `has_history` flag; return `NA` coordinates
   when `n_i==0`. *Why:* the source maps predicted-0 to NA, which would wrongly null a
   genuine (0,0); an explicit flag is robust.

10. **Haversine in C++.** → Implement great-circle distance in Rcpp (mean radius
    6371.0088 km) instead of depending on `geosphere`. *Why:* it is the hot inner loop of
    estimation/covariate building; a tiny compiled kernel keeps deps light and is the
    package's substantive compiled contribution. A pure-R reference is kept for tests.

11. **Scope: AMEN + Nigeria covariate plumbing.** The downstream AMEN network model and
    the bespoke missing-distance regression imputation are **not re-implemented** in the
    core package. → The package outputs PAL coordinates and dyadic PAL **distances**
    (linear and `log(d+0.01)`); a vignette shows feeding them to a simple dyadic model on
    simulated data. *Why:* keep the package focused, dependency-light, and broadly useful;
    re-bundling AMEN (a separate package, non-CRAN git ref) is out of scope for JOSS.

12. **Example data = simulated, not ACLED.** → Ship `simulate_conflict_events()` +
    `nigeria_sim`. *Why:* ACLED has licensing/redistribution constraints; a generator with
    mobile actor clusters reproduces the qualitative structure the method targets and
    makes examples/tests fully self-contained and deterministic (seeded).

13. **Rubin pooling completeness.** → Provide the source's normal-based
    `T=W+(1+1/m)B` plus optional Barnard–Rubin df. *Why:* exact replication by default,
    with a more complete option for general use; cross-checked against `mice::pool` in a
    (suggested-pkg-guarded) test.
