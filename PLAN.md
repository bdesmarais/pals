# Development Plan — `pals` R package + JOSS paper

Goal: a high-quality, JOSS-ready R package implementing the PALS method of Kim, Liu &
Desmarais (2023, *PSRM*, doi:10.1017/psrm.2022.6), plus a JOSS paper illustrating it.

## Guiding documents
- `docs-research/01-pals-method.md` — algorithm ground truth (from paper + Dataverse code).
- `docs-research/02-joss-requirements.md` — JOSS paper structure + review gates.
- `docs-research/03-r-package-best-practices.md` — CRAN/JOSS-grade package practices.
- `docs-research/04-domain-background.md` — exponential smoothing, Haversine, Rubin, AMEN, ACLED, ROC/PR.
- `ALGORITHM.md` — the implementation contract.
- `DESIGN.md` — API + R/C++ split.
- `DECISIONS.md` — key choices & rationale.

## Phases
1. **Guidance docs** ✔ (this set).
2. **Git + GitHub** — init, `.gitignore`, create repo via `gh`, push; commit per phase.
3. **Scaffold** — DESCRIPTION, MIT LICENSE, roxygen NAMESPACE, package doc, Rcpp wiring,
   testthat(3), `R CMD check` skeleton green.
4. **Core** — Haversine (C++), `pal_events`, projection kernel (C++ + R reference),
   `project_pal(s)`, `estimate_pals` (4- & 1-param), `predict`. Equivalence + numeric tests.
5. **Uncertainty** — `bootstrap_pals`, `pool_rubin`. Tests incl. mice cross-check.
6. **Distances/covariate** — `haversine` export, `pal_distance`, `predict_event_locations`.
7. **Data sim** — `simulate_conflict_events`, build & save `nigeria_sim`, document.
8. **Viz** — `plot_pals_map`, `plot_param_trajectory`.
9. **Docs/tests/CI** — full roxygen with runnable examples, README (badges), NEWS,
   CONTRIBUTING, CODE_OF_CONDUCT, vignette, pkgdown config, GitHub Actions
   (R-CMD-check, test-coverage, pkgdown, draft JOSS pdf). `R CMD check --as-cran` 0 errors.
10. **JOSS paper** — `paper/paper.md` + `paper/paper.bib`; compile PDF via inara if possible.
11. **Polish** — final check, tag, push, update memory.

## Definition of done
- `R CMD check` passes with no ERRORs/WARNINGs (NOTEs explained).
- `devtools::test()` all green; meaningful coverage of core paths.
- Vignette builds and renders the full workflow on `nigeria_sim`.
- README documents install + a runnable example; community files present.
- `paper.md` follows JOSS structure (Summary, Statement of need, …, References).
- GitHub repo public, regular commit history, CI configured.

## Commit cadence
Commit at the end of each phase (and at meaningful sub-steps), with descriptive messages.
