# Domain & Statistical Background for PALS

Research notes supporting an R package implementing the **PALS (Projected Actor
Locations)** method for spatial modeling of conflict between moving actors. PALS
projects each actor's geographic location forward in time using a recency-weighted
(exponential-smoothing-style) combination of its past observed locations, then uses
the great-circle **PAL distance** between two actors as a dyadic predictor of conflict
in a network model (AMEN). The method is introduced and applied in Dorff, Gallop &
Minhas's work on subnational conflict networks in Nigeria using ACLED data.

---

## 1. Exponential Smoothing & PALS as a Special Case

### Recency weighting
Exponential smoothing forms a **weighted average of past observations, with weights
decaying geometrically (exponentially) as observations get older**. The most recent
observation receives the largest weight; older observations still contribute but with
exponentially diminishing influence.

### Simple (single) exponential smoothing
The level update is the canonical recursion:

```
S_t = α · X_t + (1 − α) · S_{t−1},   with   0 < α ≤ 1
```

where `X_t` is the observation at time `t`, `S_t` the smoothed level, and `α` the
**smoothing constant / decay rate**. Higher `α` → more weight on recent data
(faster decay of old data); lower `α` → smoother, slower-adapting series.

### Geometric / exponential decay weights
Unrolling the recursion shows the weights form a geometric series:

```
S_t = α · X_t + α(1−α)·X_{t−1} + α(1−α)²·X_{t−2} + α(1−α)³·X_{t−3} + …
```

So the weight on the observation `k` steps in the past is `α(1−α)^k`. The weights sum
to 1 (a proper weighted average) and decay by the constant factor `(1−α)` per step
back in time. This is the general form of **geometric/exponential decay weights**.

### Holt's method (double exponential smoothing)
Adds a trend component for data with a linear trend (no seasonality):

```
Level:    ℓ_t = α · X_t + (1 − α)(ℓ_{t−1} + b_{t−1})
Trend:    b_t = β · (ℓ_t − ℓ_{t−1}) + (1 − β) · b_{t−1}
Forecast: X̂_{t+h} = ℓ_t + h · b_t
```

with a second smoothing parameter `β` for the trend. Holt–Winters adds a third
component for seasonality.

### Why PALS is "a special case of exponential smoothing"
PALS projects an actor's location at time `t` as a **recency-weighted average of its
previously observed locations** (e.g., separate smoothing of latitude and longitude, or
a weighted centroid). Because the projection weights past positions with geometrically
decaying weights governed by a decay parameter, it is structurally a single-exponential-
smoothing forecast applied to spatial coordinates — recent positions dominate the
projected location, but the actor's history still informs it. The decay parameter(s) are
estimated from preceding-period event data (in the source work, via a hill-climbing
optimization), rather than fixed a priori.

---

## 2. Haversine Formula (Great-Circle Distance)

The PAL distance between two projected actor locations is a great-circle distance on a
sphere, computed with the **haversine formula**. Given two points with latitudes
`φ₁, φ₂` and longitudes `λ₁, λ₂` (in **radians**), let `Δφ = φ₂ − φ₁` and
`Δλ = λ₂ − λ₁`:

```
a = sin²(Δφ / 2) + cos(φ₁) · cos(φ₂) · sin²(Δλ / 2)
c = 2 · arcsin( min(1, √a) )      (equivalently c = 2 · atan2(√a, √(1−a)))
d = R · c
```

- The haversine function is `hav(θ) = sin²(θ/2)`.
- `R` is Earth's **mean radius ≈ 6371 km** (6371000 m; ≈ 3959 miles). Earth's radius
  actually ranges from ~6356.752 km (poles) to ~6378.137 km (equator); 6371 km is the
  standard mean approximation.
- The `min(1, √a)` / `atan2` form guards against floating-point domain errors and is
  numerically stable for both very small and antipodal distances.

### Comparison with other distance methods
- **Euclidean (planar)**: treats lat/long as flat Cartesian coordinates. Ignores Earth
  curvature; acceptable only over very short spans and badly distorted near the poles or
  over long distances. Not appropriate for country-scale PAL distances.
- **Haversine**: assumes a **perfect sphere**. Simple, fast, robust; error vs. the true
  ellipsoid is up to ~0.3–0.5% (worst case tens of km on very long lines). Sufficient for
  almost all conflict-distance applications.
- **Vincenty / Karney**: model Earth as an **oblate spheroid (WGS-84 ellipsoid)** via
  iterative formulae; accurate to sub-millimeter but more complex and can fail to
  converge for near-antipodal points. Matters for geodesy/surveying, overkill for PALS.

For PALS, haversine is the natural choice: it is curvature-correct, cheap to evaluate
across many dyads, and far more accurate than Euclidean at the spatial scale of a country.

---

## 3. Multiple Imputation & Rubin's Rules

PALS uses a **bootstrap** to propagate uncertainty in the estimated smoothing/decay
parameters into the PAL distances, producing `M` replicate "completed" distance
datasets. These replicate estimates are then combined with **Rubin's Rules**, the
standard machinery for pooling estimates and variances across `M` imputations/replicates.

Let `Q̂_m` be the point estimate and `Û_m` its (within-replicate) sampling variance from
replicate `m = 1, …, M`.

**Pooled point estimate** (average of the estimates):
```
Q̄ = (1/M) · Σ_m  Q̂_m
```

**Within-imputation variance** (average of the variances):
```
Ū = (1/M) · Σ_m  Û_m
```

**Between-imputation variance** (variance of the estimates across replicates):
```
B = (1/(M − 1)) · Σ_m  (Q̂_m − Q̄)²
```

**Total variance**:
```
T = Ū + (1 + 1/M) · B
```

- `Ū` captures ordinary sampling variability.
- `B` captures the extra uncertainty introduced by the missing-data / estimation
  variability (here, uncertainty in the projected locations / parameters).
- The factor `(1 + 1/M)` (the `B/M` term) corrects for using a **finite** number of
  replicates; omitting it yields confidence intervals that are too narrow and p-values
  too small, especially for small `M`.

Inference uses `Q̄ ± t_ν · √T`, with a Rubin–Barnard degrees-of-freedom approximation
based on the relative increase in variance due to missingness,
`r = (1 + 1/M)·B / Ū`. The standard error of the pooled PAL-distance estimate is `√T`.

---

## 4. Bootstrap Resampling

The **bootstrap** quantifies uncertainty by resampling the observed data **with
replacement**.

Procedure:
1. From the original sample of size `n`, draw a bootstrap sample of size `n` **with
   replacement** — some observations appear multiple times, others not at all.
2. Recompute the statistic of interest `θ̂*` on the resample (in PALS: re-estimate the
   smoothing/decay parameters and recompute PAL distances).
3. Repeat `B` times to obtain replicates `θ̂*₁, …, θ̂*_B`, forming an empirical sampling
   distribution of the statistic.

From the replicates:
- **Standard error** ≈ standard deviation of the bootstrap replicates,
  `SE = sd(θ̂*_1, …, θ̂*_B)`.
- **Confidence intervals** via the percentile method (e.g., 2.5th–97.5th percentiles of
  the replicates) or BCa.
- **Bias** ≈ `mean(θ̂*) − θ̂`.

Typically `B` ≈ 1,000–10,000 replicates for stable estimates; more replicates reduce
Monte Carlo error at higher compute cost. In PALS, the bootstrap replicates of the PAL
distances feed directly into the Rubin's-Rules pooling of Section 3, so downstream model
estimates reflect location-projection uncertainty rather than treating projected
locations as fixed/known.

---

## 5. The AMEN Model (Additive and Multiplicative Effects Networks)

**AMEN** (Hoff) is a statistical framework for **dyadic / relational (network) data**,
extending linear/regression and random-effects models with terms that capture network
dependence. The R package is **`amen`** (CRAN and `pdhoff/amen` on GitHub); the main
fitting function is **`ame()`**, with Bayesian (MCMC/Gibbs) estimation.

### Model form
For a directed/undirected relation `y_{i,j}` between sender `i` and receiver `j`:

```
y_{i,j}  ~  β'x_{i,j}  +  a_i  +  b_j  +  u_i' v_j  +  ε_{i,j}
```

Components:
- **β'x_{i,j} — dyadic (and nodal) covariates.** Observed predictors enter as a linear
  regression term. **A PAL distance for the dyad `(i,j)` enters exactly here as a dyadic
  covariate `x_{i,j}`**; its coefficient `β` measures how projected proximity relates to
  conflict propensity (expectation: closer projected actors → higher conflict
  probability, i.e., a negative coefficient on distance).
- **a_i, b_j — additive sender/receiver random effects.** Capture second-order
  structure: out-degree (sender) and in-degree (receiver) heterogeneity, and (via their
  joint covariance) within-dyad correlation / reciprocity.
- **u_i' v_j — multiplicative latent-factor term.** Low-dimensional latent vectors whose
  inner product captures third-order dependence (transitivity, clustering, stochastic
  equivalence) — the "what lies beneath" latent network structure.
- **ε_{i,j} — residual dyadic noise**, with correlated within-dyad errors.

### Outcome types
`ame()` supports several link/likelihood families: continuous (Gaussian) relational
data, **binary** (probit) network ties, **ordinal**, tobit/zero-inflated positive
outcomes, and fixed-rank nomination. For conflict prediction the **binary** family is
the natural choice (conflict / no conflict per directed dyad per period).

In the PALS workflow, AMEN is the outcome model: the bootstrapped, Rubin-pooled PAL
distances are supplied as the dyadic covariate, and the additive + multiplicative
effects soak up the network dependence that a plain logistic/GLM dyadic regression would
ignore.

---

## 6. ACLED & the Nigerian Conflict Context

### ACLED
The **Armed Conflict Location & Event Data Project (ACLED)** is a non-profit (founded
2005 by Clionadh Raleigh) that collects, codes, and maps real-time data on political
violence and protest worldwide. Each **event record** is a single geolocated incident
with ~31 fields, including:

- **Event date** and a unique event identifier
- **Event type** (six top-level types: battles; explosions/remote violence; violence
  against civilians; riots; protests; strategic developments) plus sub-event types
- **Actors** (`actor1`, `actor2`, plus associated/allied actors) — named armed groups,
  state forces, militias, communal groups, etc.
- **Location** with **latitude and longitude** (plus admin1/admin2 names and a
  geo-precision code)
- **Fatalities** count and free-text **notes** describing the incident
- Source/sourcing metadata

These geolocated, actor-tagged, dated events are exactly what PALS needs: actor identity
+ time + lat/long lets one observe each armed group's historical positions and project
them forward.

### Nigeria, ~2000–2016
The empirical application covers Nigerian conflict over roughly 2000–2016. This period
spans multiple, partly overlapping armed conflicts and many actors — e.g., the Boko Haram
insurgency in the northeast (escalating from ~2009), Fulani/herder–farmer communal
violence in the Middle Belt, militancy in the Niger Delta, and assorted state forces,
vigilante/self-defense groups, and political militias. Many of these actors are **mobile**
(their centers of activity shift year to year), which motivates projecting actor
locations rather than treating them as static — the core rationale for PALS.

### Dorff, Gallop & Minhas (study replicated/extended)
PALS builds on and extends **Dorff & Gallop & Minhas**, "Networks of Violence: Predicting
Conflict in Nigeria" (*Journal of Politics*, 2020), which models subnational conflict in
Nigeria as a **network of armed actors** and shows that latent network structure
(additive + multiplicative effects, à la AMEN) improves prediction of who fights whom.
Related/companion work includes "What lies beneath: using latent networks to improve
spatial predictions" and "Spatial modeling of dyadic geopolitical interactions between
moving actors." PALS extends this line by adding the **projected-location dyadic
covariate** (PAL distance) — capturing the spatial dimension of which actors are likely
to come into contact — and propagating its estimation uncertainty into the network model.

---

## 7. Predictive Evaluation: ROC/AUC and Precision–Recall/AUC-PR

Conflict prediction is **dyadic and highly imbalanced**: among all possible actor pairs
in a period, only a small fraction actually fight. Two complementary curve-based,
threshold-free metrics are used.

### ROC curve and AUC
Plots **True Positive Rate** (recall, `TP/(TP+FN)`) against **False Positive Rate**
(`FP/(FP+TN)`) across all classification thresholds. **AUC-ROC** is the area under it;
0.5 = random, 1.0 = perfect. AUC-ROC equals the probability that a randomly chosen
positive dyad is ranked above a randomly chosen negative one.

### Precision–Recall curve and AUC-PR
Plots **Precision** (`TP/(TP+FP)`) against **Recall** (`TP/(TP+FN)`). **AUC-PR**
(average precision) is the area under it. The **baseline** for a random classifier is not
0.5 but the **prevalence** (the positive rate) — e.g., if 2% of dyads are conflicts, the
PR baseline is 0.02.

### Why PR curves matter for rare-event / imbalanced dyadic prediction
- ROC's FPR is normalized by the (huge) number of true negatives. With extreme imbalance,
  a large absolute number of false positives barely moves FPR, so **ROC-AUC can look
  deceptively high** even when the model is poor at actually flagging the rare positives.
- **Precision and recall ignore true negatives entirely**, so the PR curve stays
  sensitive to performance on the minority (conflict) class — the class we care about.
- The stronger the imbalance, the larger the gap between ROC-AUC and PR-AUC tends to be.
  A high **PR-AUC relative to the prevalence baseline** is the more trustworthy evidence
  that the model genuinely finds rare conflict dyads.

Practical recommendation for PALS: report **both** ROC-AUC and PR-AUC, but treat
**PR-AUC (against the prevalence baseline)** as the primary discriminating metric, and
compare models (e.g., with vs. without the PAL-distance covariate) on it.

---

## Sources

- Spatial modeling of dyadic geopolitical interactions between moving actors (PALS paper, repository PDF): https://repository.essex.ac.uk/32243/1/div-class-title-spatial-modeling-of-dyadic-geopolitical-interactions-between-moving-actors-div.pdf
- Spatial modeling of dyadic geopolitical interactions between moving actors (Cambridge Core, PSRM): https://www.cambridge.org/core/journals/political-science-research-and-methods/article/spatial-modeling-of-dyadic-geopolitical-interactions-between-moving-actors/9D4F222413B90228EBFC78D61DB70287
- Dorff, Gallop & Minhas, "Networks of Violence: Predicting Conflict in Nigeria," Journal of Politics (2020): https://www.journals.uchicago.edu/doi/abs/10.1086/706459
- "What lies beneath: using latent networks to improve spatial predictions": https://pureportal.strath.ac.uk/en/publications/what-lies-beneath-using-latent-networks-to-improve-spatial-predic/
- Exponential smoothing — Wikipedia: https://en.wikipedia.org/wiki/Exponential_smoothing
- Exponential smoothing (geometric decay weights) — PSU STAT 501: https://online.stat.psu.edu/stat501/lesson/t/t.2/t.2.5/t.2.5.2-exponential-smoothing
- Holt-Winters exponential smoothing: https://timeseriesreasoning.com/contents/holt-winters-exponential-smoothing/
- Haversine formula — Wikipedia: https://en.wikipedia.org/wiki/Haversine_formula
- Great-circle distance — Wikipedia: https://en.wikipedia.org/wiki/Great-circle_distance
- Haversine vs. Vincenty comparison: https://medium.com/@herihermawan/comparing-the-haversine-and-vincenty-algorithms-for-calculating-great-circle-distance-5a2165857666
- Lat/long distance & bearing (haversine reference implementation): https://www.movable-type.co.uk/scripts/latlong.html
- Rubin's Rules (Heymans & Eekhout, Applied Missing Data Analysis): https://bookdown.org/mwheymans/bookmi/rubins-rules.html
- van Buuren, Flexible Imputation of Missing Data (MI in a nutshell): https://stefvanbuuren.name/fimd/sec-nutshell.html
- Combining estimates after multiple imputation (Marshall et al., PMC): https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2727536/
- Bootstrap resampling essentials in R — STHDA: https://www.sthda.com/english/articles/38-regression-model-validation/156-bootstrap-resampling-essentials-in-r/
- Bootstrap — Alan Turing Institute intro to ML: https://alan-turing-institute.github.io/Intro-to-transparent-ML-course/05-cross-val-bootstrap/bootstrap.html
- amen: Additive and Multiplicative Effects Models (package site): https://pdhoff.github.io/amen/
- amen on GitHub (Peter Hoff): https://github.com/pdhoff/amen
- Hoff, "Dyadic data analysis with amen" (arXiv 1506.08237): https://arxiv.org/abs/1506.08237
- amen on CRAN: https://cran.r-project.org/package=amen
- Minhas, Hoff & Ward, "Additive and Multiplicative Effects Network Models," Statistical Science (2021): https://projecteuclid.org/journals/statistical-science/volume-36/issue-1/Additive-and-Multiplicative-Effects-Network-Models/10.1214/19-STS757.pdf
- ACLED — official site: https://acleddata.com/
- Armed Conflict Location and Event Data — Wikipedia: https://en.wikipedia.org/wiki/Armed_Conflict_Location_and_Event_Data
- Precision-Recall is more informative than ROC in imbalanced data — Towards Data Science: https://towardsdatascience.com/precision-recall-curve-is-more-informative-than-roc-in-imbalanced-data-4c95250242f6/
- ROC AUC vs Precision-Recall for imbalanced data — Machine Learning Mastery: https://machinelearningmastery.com/roc-auc-vs-precision-recall-for-imbalanced-data/
- Sofaer, Hoeting & Jarnevich, "The area under the precision-recall curve as a performance metric for rare binary events," Methods in Ecology and Evolution (2019): https://besjournals.onlinelibrary.wiley.com/doi/10.1111/2041-210X.13140
