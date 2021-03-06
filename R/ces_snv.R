#' Calculate selection intensity for single-nucleotide variants and amino acid changes
#' @param cesa CESAnalysis object
#' @param gene which genes to calculate effect sizes within; defaults to all genes with recurrent mutations in data set
#' @param cores number of cores to use
#' @param include_genes_without_recurrent_mutations default false; will increase runtime and won't find anything interesting
#' @return CESAnalysis object with selection results added for the chosen analysis
#' @export

ces_snv <- function(cesa = NULL,
                            genes = "all",
                            cores = 1,
                            include_genes_without_recurrent_mutations = F,
                            find_CI=T) 
{
  if (! "character" %in% class(genes)) {
    stop("Expected argument \"genes\" to take a character vector.")
  }

  # using the "SNV" genes
  snv.maf = cesa@maf[Variant_Type == "SNV"]
  genes_in_dataset = unique(snv.maf$Gene_name)
  if(length(genes_in_dataset) == 0) {
    stop("The SNV mutation data set is empty!")
  }


  if(genes[1] =="all") {
    if (include_genes_without_recurrent_mutations) {
      genes_to_analyze <- genes_in_dataset
    } else {
      tmp = table(snv.maf$unique_variant_ID)
      recurrent_variants = names(tmp[tmp > 1])
      has_recurrent = snv.maf$unique_variant_ID %in% recurrent_variants
      genes_to_analyze = unique(snv.maf$Gene_name[has_recurrent])
      message(paste(length(genes_in_dataset) - length(genes_to_analyze), "genes in the data set have no recurrent SNV mutations."))
      message(paste("Calculating selection intensity for recurrent SNV mutations across", length(genes_to_analyze), "genes."))
    }
  } else{
    genes = unique(genes)
    genes_to_analyze <- genes[genes %in% genes_in_dataset]
    missing_genes = genes[! genes %in% genes_in_dataset]
    gene_names = get_genome_data(cesa, "gene_names")
    invalid_genes = missing_genes[! missing_genes %in% gene_names]
    num_invalid = length(invalid_genes)
    if(num_invalid > 0) {
      additional_msg = ""
      if(num_invalid > 50) {
        invalid_genes = invalid_genes[1:40]
        additional_msg = paste0(" (and ", num_invalid - 40, " more)")
      }
      list_of_invalid = paste(invalid_genes, collapse = ", ")
      stop(paste0("Note: The following requested genes were not found in reference data for your genome build:\n\t",
                  list_of_invalid, additional_msg, "\n"))
    }
    if (length(genes_to_analyze) == 0) {
      stop("None of the requested genes have mutations in the SNV data set.")
    }

    num_missing = length(missing_genes)
    if(num_missing > 0) {
      additional_msg = ""
      if(num_missing > 50) {
        missing_genes = missing_genes[1:40]
        additional_msg = paste0(" (and ", num_missing - 40, " more)")
      }
      list_of_missing = paste(missing_genes, collapse = ", ")

      message(paste0("The following requested genes have no mutations in the SNV data set, so they won't be analyzed:\n\t",
        list_of_missing, additional_msg))
    }
  }

  gene_trinuc_comp = get_genome_data(cesa, "gene_trinuc_comp")
  selection_results <- rbindlist(pbapply::pblapply(genes_to_analyze, get_gene_results, cesa = cesa,
                                             gene_trinuc_comp = gene_trinuc_comp, find_CI=find_CI, cl = cores))
  cesa@selection_results = selection_results
  cesa@status[["SNV selection"]] = "view effect sizes with snv_results()"
  return(cesa)
}


#' Single-stage SNV effect size analysis (gets called by ces_snv)
#' @keywords internal
get_gene_results <- function(gene, cesa, find_CI, gene_trinuc_comp) {
  snv.maf = cesa@maf[Variant_Type == "SNV"]
  current_gene_maf = snv.maf[Gene_name == gene]
  these_mutation_rates <-
    mutation_rate_calc(
      this_MAF = current_gene_maf,
      gene = gene,
      gene_mut_rate = cesa@mutrates_list,
      trinuc_proportion_matrix = cesa@trinucleotide_mutation_weights$trinuc_proportion_matrix,
      gene_trinuc_comp = gene_trinuc_comp,
      samples = cesa@samples)

  variants = colnames(these_mutation_rates)
  process_variant = function(variant) {
    # use the first matching record as the locus 
    # (will assume that for amino acid variants, coverage at one site in codon implies coverage for whole codon)
    variant_maf = current_gene_maf[unique_variant_ID_AA == variant] # no need to subset further because already dealing with a gene-specific MAF
    # covered_in is a 1-item list with a character vector of coverage_grs that cover the variant site
    site_coverage = unlist(variant_maf[1, covered_in])
    eligible_tumors = cesa@samples[covered_regions %in% site_coverage, Unique_Patient_Identifier]
    

    
    # given the tumors with coverage, their mutation rates at the variant sites, and their mutation status,
    # find most likely selection intensities (by stage if applicable)
    optimization_output <- optimize_gamma(
      MAF_input = current_gene_maf,
      eligible_tumors = eligible_tumors,
      gene=gene,
      variant=variant,
      progressions = cesa@progressions,
      samples = cesa@samples,
      specific_mut_rates=these_mutation_rates)
    
    selection_intensity = optimization_output$par
    loglikelihood = rep(optimization_output$value, length(selection_intensity))
    unsure_gene_name = rep(variant_maf$unsure_gene_name[1], length(selection_intensity))
    progression_name = cesa@progressions
    if (length(cesa@progressions) == 1) {
      progression_name = "Not applicable"
    }
    
    # Note: since DNV/TNV have been removed, should not get any duplicate entries here
    tumors_with_pos_mutated <- variant_maf$Unique_Patient_Identifier
    stages = cesa@samples[tumors_with_pos_mutated, progression_name]
    # This gives number of tumors of each stage with the variant (in proper progression order)
    tumors_with_variant = as.numeric(table(factor(stages, levels = cesa@progressions)))
    
    # Also get number of eligible tumors per stage
    tumor_stages = cesa@samples[eligible_tumors, progression_name]
    tumors_with_coverage = as.numeric(table(factor(tumor_stages, levels = cesa@progressions)))
    
    dndscv_q = sapply(cesa@dndscv_out_list, function(x) x$sel_cv[x$sel_cv$gene_name == gene, "qallsubs_cv"])
    
    variant_id = variant
    if (variant_maf$is_coding[1] == TRUE) {
      variant_id = paste(gene, variant_id)
    }
    variant_id = rep(variant_id,  length(selection_intensity))
    gene = rep(gene, length(selection_intensity))
    
    variant_output = data.table(variant = variant_id, selection_intensity, unsure_gene_name, loglikelihood, gene, 
                         progression = progression_name, tumors_with_variant, tumors_with_coverage, dndscv_q)
    
    if(length(cesa@progressions) == 1 & find_CI){
      # find CI function
      CI_results <- CI_finder(gamma_max = optimization_output$par,
                                                 MAF_input= current_gene_maf,
                                                 eligible_tumors = eligible_tumors,
                                                 samples = cesa@samples,
                                                 gene=gene,
                                                 variant=variant,
                                                 specific_mut_rates=these_mutation_rates)
      
      
      variant_output$ci_low_999 <- CI_results$lower_CI
      variant_output$ci_high_999 <- CI_results$upper_CI
      
      CI_results <- CI_finder(gamma_max = optimization_output$par,
                                                 MAF_input= current_gene_maf,
                                                 eligible_tumors = eligible_tumors,
                                                 samples = cesa@samples,
                                                 gene=gene,
                                                 variant=variant,
                                                 specific_mut_rates=these_mutation_rates,
                                                 log_units_down = 1.92 # 95% confidence interval
      )
      variant_output$ci_low_95 <- CI_results$lower_CI
      variant_output$ci_high_95 <- CI_results$upper_CI
      
    }
    return(variant_output)
  }
  return(data.table::rbindlist(lapply(variants, process_variant)))
}





