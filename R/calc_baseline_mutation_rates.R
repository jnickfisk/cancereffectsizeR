#' calc_baseline_mutation_rates
#' 
#' Wrapper to sequentially run the functions trinuc_mutation_rates, gene_mutation_rates, and
#' annotate_variants. If you want to run these functions with advanced, non-default settings, see the
#' documentation for each function and run the functions individually instead of using this wrapper.
#'
#' @param cesa CESAnalysis object
#' @param cores number of cores to use for calcualtions that can parallelized (requires parallel package)
#' @param signatures mutational signatures to which to attribute mutational processes in each tumor: "cosmic_v3" (default), 
#'                   "cosmic_v2" ,or a properly-formatted user-supplied signatures data.frame
#' @param covariate_file tissue-specific covariate file for dNdScv (gene-level mutation rate calculation)
#' @export



calc_baseline_mutation_rates <- function(
      cesa = NULL,
      covariate_file=NULL,
      cores = 1,
      signatures = "cosmic_v3"
) 
{

  if (! is.numeric(cores) || length(cores) > 1) {
    stop("cores should be a 1-length numeric")
  }
  
  # Calculate trinucleotide mutation weightings using deconstructSigs
  cesa = trinuc_mutation_rates(cesa, signature_choice  = signatures, cores = cores)

  # Calculate gene-level mutation rates using dNdScv
  cesa = gene_mutation_rates(cesa, covariate_file = covariate_file)

  # Assign genes to MAF, keeping assignments consistent with dndscv when possible
  cesa = annotate_variants(cesa)

  return(cesa)
}


