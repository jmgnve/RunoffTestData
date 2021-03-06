# Run evaluation for all stations for one model
#
# Required inputs:
#
# q_obs and q_sim - data frames containing observed and simulated discharge
#
# model_name - name of the model
# model_version - version of the model
# model_desc - additional information about the model
# model_input - information about model input
# model_res - information about location of model results
# period - calibration or validation period ("calib" or "valid")

run_evaluation <- function(q_obs, q_sim, model_name, model_version, model_desc, model_input, model_res, period) {
  
  # Required libraries
  
  require(hydroGOF)
  
  # Stop if data frames do not contain identical time steps and stations
  
  stopifnot(identical(q_sim$Time, q_obs$Time))
  stopifnot(identical(colnames(q_sim), colnames(q_obs)))
  
  # Evaluation period
  
  days_warmup <- 3*365
  
  ieval <- days_warmup:nrow(q_sim)
  
  # Prepare data frames
  
  time <- q_obs$Time[ieval]
  
  q_obs <- q_obs[ieval, 2:ncol(q_obs)]
  q_sim <- q_sim[ieval, 2:ncol(q_sim)]
  
  # Allocation of outputs
  
  KGE2009 <- c()
  KGE2012 <- c()
  r <- c()
  Alpha <- c()
  Beta <- c()
  Gamma <- c()
  NSE <- c()
  NSE_bench <- c()
  Intercept <- c()
  Slope <- c()
  r2 <- c()
  Bias <- c()
  Pbias <- c()
  
  # Compute performance measures for each station
  
  for (istat in 1:ncol(q_obs)) {
    
    # Compute original KGE (Gupta2009)
    
    KGE2009_tmp <- hydroGOF::KGE(q_sim[, istat], q_obs[, istat], na.rm=TRUE, method="2009", out.type = "full")
    
    KGE2009[istat] <- KGE2009_tmp$KGE.value
    
    # Compute modified KGE (Kling2012)
    
    KGE2012_tmp <- hydroGOF::KGE(q_sim[, istat], q_obs[, istat], na.rm=TRUE, method="2012", out.type = "full")
    
    KGE2012[istat] <- KGE2012_tmp$KGE.value
    
    # Get components of KGE
    
    r[istat] <- KGE2012_tmp$KGE.elements[1]
    
    Alpha[istat] <- KGE2009_tmp$KGE.elements[2]
    
    Beta[istat] <- KGE2012_tmp$KGE.elements[2]
    
    Gamma[istat] <- KGE2012_tmp$KGE.elements[3]
    
    # Compute NSE
    
    NSE[istat] <- hydroGOF::NSE(q_sim[, istat], q_obs[, istat], na.rm=TRUE)
    
    # Compute NSE_bench
    
    NSE_bench[istat] <- NSE_bench(time, q_sim[, istat], q_obs[, istat])
    
    # Regression statistics
    
    fit <- lm(q_sim[, istat] ~ q_obs[, istat])
    
    Intercept[istat] <- fit$coefficients[[1]]
    
    Slope[istat] <- fit$coefficients[[2]]
    
    r2[istat] <- cor(q_obs[, istat], q_sim[, istat], use = "complete.obs")^2
    
    # Compute bias
    
    Bias[istat] <- hydroGOF::me(q_sim[, istat], q_obs[, istat])
    
    Pbias[istat] <- hydroGOF::pbias(q_sim[, istat], q_obs[, istat])    
    
  }
  
  # Round results
  
  KGE2009   <- round(KGE2009, digits = 2)
  KGE2012   <- round(KGE2012, digits = 2)
  r         <- round(r, digits = 2)
  Alpha     <- round(Alpha, digits = 2)
  Beta      <- round(Beta, digits = 2)
  Gamma     <- round(Gamma, digits = 2)
  NSE       <- round(NSE, digits = 2)
  NSE_bench <- round(NSE_bench, digits = 2)
  Intercept <- round(Intercept, digits = 2)
  Slope     <- round(Slope, digits = 2)
  r2        <- round(r2, digits = 2)
  Bias      <- round(Bias, digits = 2)
  Pbias     <- round(Pbias, digits = 2)
  
  # Data frame with outputs
  
  res <- data.frame(Station   = colnames(q_obs),
                    KGE2009   = KGE2009,
                    KGE2012   = KGE2012,
                    r         = r,
                    Beta      = Beta,
                    Alpha     = Alpha,
                    Gamma     = Gamma,
                    NSE       = NSE,
                    NSE_bench = NSE_bench,
                    Intercept = Intercept,
                    Slope     = Slope,
                    r2        = r2,
                    Bias      = Bias,
                    Pbias     = Pbias)  
  
  # Save data to file
  
  filename = paste("24h/results", "_", period, "/", model_name, "_", model_version, ".txt", sep = "")
  
  if (file.exists(filename)) {
    stop(paste("File ", filename, " already exists. Delete it manually to replace it.", sep = ""))
  }
  
  model_name <- paste("Model:", model_name)
  model_version <- paste("Version:", model_version)
  model_period <- paste("Period:", head(time,1), "to", tail(time,1))
  file_created <- paste("Time of file generation:", Sys.time())
  model_desc <- paste("Description:", model_desc)
  model_input <- paste("Model input:", model_input)
  model_res <- paste("Path to model results:", model_res)
  
  cat(model_name, file = filename, sep = "\n")
  cat(model_version, file = filename, sep = "\n", append = TRUE)
  cat(model_period, file = filename, sep = "\n", append = TRUE)
  cat(file_created, file = filename, sep = "\n", append = TRUE)
  cat(model_desc, file = filename, sep = "\n", append = TRUE)
  cat(model_input, file = filename, sep = "\n", append = TRUE)
  cat(model_res, file = filename, sep = "\n", append = TRUE)
  cat("", file = filename, sep = "\n", append = TRUE) # Place holder in case of adding additional info
  cat("", file = filename, sep = "\n", append = TRUE) # Place holder in case of adding additional info
  cat("", file = filename, sep = "\n", append = TRUE) # Place holder in case of adding additional info
  
  write.table(res, file = filename, quote = FALSE, sep = "\t", row.names = FALSE, append = TRUE)
  
}





























