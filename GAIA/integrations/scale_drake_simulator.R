# scale_drake_simulator.R — local stochastic Drake-equation compatibility adapter.
# This does not invoke the Scala SCALE engine; it is retained until NEXUS
# versioned contracts replace compatibility emulators.

N_ITERATIONS <- 10000
SEED <- 42
set.seed(SEED)

results <- data.frame(
  iteration = 1:N_ITERATIONS,
  R_star = rgamma(N_ITERATIONS, shape = 3, rate = 1),
  f_p = rbeta(N_ITERATIONS, 2, 3),
  n_e = rpois(N_ITERATIONS, lambda = 2) + 0.1,
  f_l = rbeta(N_ITERATIONS, 1.5, 5),
  f_i = rbeta(N_ITERATIONS, 1, 10),
  f_c = rbeta(N_ITERATIONS, 1, 20),
  L = rlnorm(N_ITERATIONS, meanlog = 7, sdlog = 2)
)
results$N_civilizations <- with(results, R_star * f_p * n_e * f_l * f_i * f_c * L)

cat("[GAIA-SCALE-COMPAT] Drake Equation Monte Carlo\n")
cat(sprintf("  Seed:           %d\n", SEED))
cat(sprintf("  Iterations:     %d\n", N_ITERATIONS))
cat(sprintf("  Median N:       %.1f\n", median(results$N_civilizations)))
cat(sprintf("  Mean N:         %.1f\n", mean(results$N_civilizations)))
cat(sprintf("  95%% interval:   [%.1f, %.1f]\n",
            quantile(results$N_civilizations, 0.025),
            quantile(results$N_civilizations, 0.975)))

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "integrations/scale_drake_simulator.R"
script_dir <- dirname(normalizePath(script_path, mustWork = FALSE))
project_dir <- dirname(script_dir)
output_path <- file.path(project_dir, "data", "raw", "drake_monte_carlo.csv")
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(results, output_path, row.names = FALSE)
cat(sprintf("[GAIA-SCALE-COMPAT] Results exported to: %s\n", output_path))
