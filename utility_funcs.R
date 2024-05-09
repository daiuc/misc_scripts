#' Frequently re-used custom functions


readNominal = function(nominal.f, nominal.suf = "Nominal.txt.gz", gr, nom_cols) {
  #' @description  : read nominal pass results into a data.table
  #'
  #' @nominal.f    : character, tabix indexed nominal pass result file prefix
  #' @nominal.suf  : character, suffice for the nominal file, if nominal.f is
  #'                 given as prefix, default "Nominal.txt.gz"
  #' @gr           : GRange object, of the queried region
  #' @pid_col      : character, column name for phenotype id
  #' @nom_cols     : vector, column nmaes for nominal pass file
  #'
  #' @return       : data.table, nominal pass results for the queried region
  #'                 for the phenotype

  c = seqnames(gr) %>% as.vector
  s = start(gr)
  e = end(gr)

  if (file.info(nominal.f)$isdir) {
    # fill in full file path using chrom from gr, and prefix, suffix
    f = glue(nominal.f, "/", {c}, "/", {nominal.suf})
  } else {
    f = nominal.f
  }
  if (!file.exists(f)) stop(glue("File {f} does not exist!"))

  CMD = glue("tabix {f} {c}:{s}-{e}")
  dt = fread(cmd = CMD, col.names = nom_cols) # read nominal snps in  region
  if (nrow(dt) > 0) {
    dt = dt[pid %in% mcols(gr)[['pid']]] # only want snps for given pheno
  }

  return(dt)
}


concatLabels <- function(data, byCol, oldLabel, newLabel) {
        #' @param data    : data.table
        #' @param byCol   : group by column, typically key
        #' @param oldLabel: label to concat
        #' @param newLabel: label after concat
    
        env = list(byCol = byCol, oldLabel = oldLabel, newLabel = newLabel)
        env = lapply(env, as.name)
        expr1 = substitute(paste0(unique(oldLabel), collapse = ","), env)
        expr2 = substitute(byCol, env)
        
        data = eval(substitute(data[, .(new = expr1), by = expr2]))
        setnames(data, "new", newLabel)
        unique(data)
}






multiqq <- function(pvalues) {
    punif <- -log10(runif(max(sapply(pvalues, length))))
    df <- do.call(rbind, foreach(i = seq_len(length(pvalues))) %do% {
        df <- as.data.frame(
            qqplot(
                x = punif[1:length(pvalues[[i]])],
                y = -log10(pvalues[[i]]),
                plot.it = FALSE
            )
        )
        df$group <- names(pvalues)[i]
        df
    })
    df$group <- factor(df$group, names(pvalues))
    ggplot(df, aes(x, y, col = group)) +
        geom_point() +
        geom_abline(
            intercept = 0,
            slope = 1
        ) +
        xlab("Expected -log10(p)") +
        ylab("Observed -log10(p)")
}




