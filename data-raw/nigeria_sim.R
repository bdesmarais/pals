# Build the bundled `nigeria_sim` example dataset.
#
# A deterministic, seeded simulation of dyadic conflict events among mobile actors
# in a Nigeria-like geographic frame. Used in examples, tests, and the vignette so
# they run with no external dependency, alongside the real `nigeria_acled` data.
#
# Run with:  source("data-raw/nigeria_sim.R")  (from the package root, with the
# package loaded via devtools::load_all()).

nigeria_sim <- simulate_conflict_events(
  n_actors = 25,
  n_events = 1500,
  years    = 2000:2016,
  seed     = 20230101
)

usethis::use_data(nigeria_sim, overwrite = TRUE)
