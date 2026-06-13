# Generate the figure used in the JOSS paper (paper/figure-trajectories.png).
#
# Illustrates the core idea of PALS: actors are *mobile*, so their projected
# locations trace a trajectory through space over time. We fit the one-parameter
# model to the bundled `nigeria_sim` data and project a handful of actors at
# yearly intervals, drawing each actor's projected path over the cloud of
# observed events.
#
# Run from the package root with the package loaded:
#   Rscript paper/make_figure.R

suppressMessages({
  if (requireNamespace("palsr", quietly = TRUE)) {
    library(palsr)
  } else {
    # Development fallback: load the source tree in place.
    devtools::load_all(quiet = TRUE)
  }
  library(ggplot2)
})

data(nigeria_sim)
fit <- estimate_pals(nigeria_sim, model = "one")

actors <- c("G03", "G08", "G14", "G21")
dates  <- as.Date(sprintf("%d-01-01", seq(2005, 2016, by = 1)))

traj <- project_pals(nigeria_sim, actors = actors,
                     predict_time = dates, params = fit)
traj <- traj[!is.na(traj$lon), ]
traj$year <- as.integer(format(traj$time, "%Y"))
ends <- do.call(rbind, lapply(split(traj, traj$actor),
                              function(d) d[which.max(d$time), ]))

p <- ggplot() +
  geom_point(data = nigeria_sim, aes(lon, lat),
             colour = "grey80", size = 0.5, alpha = 0.5) +
  geom_path(data = traj, aes(lon, lat, colour = actor),
            linewidth = 0.8, lineend = "round",
            arrow = grid::arrow(length = grid::unit(0.18, "cm"), type = "closed")) +
  geom_point(data = traj, aes(lon, lat, colour = actor), size = 1.6) +
  geom_text(data = ends, aes(lon, lat, colour = actor, label = actor),
            nudge_y = 0.35, size = 3.2, show.legend = FALSE) +
  scale_colour_brewer(palette = "Dark2", name = "Actor") +
  labs(x = "Longitude", y = "Latitude") +
  coord_quickmap() +
  theme_minimal(base_size = 11) +
  theme(legend.position = "right",
        panel.grid.minor = element_blank())

ggsave("paper/figure-trajectories.png", p, width = 6.5, height = 4.2,
       dpi = 150, bg = "white")
cat("wrote paper/figure-trajectories.png\n")
