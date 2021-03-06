% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/trinuc_mutation_rates.R
\name{trinuc_mutation_rates}
\alias{trinuc_mutation_rates}
\title{Calculate relative rates of trinucleotide-context-specific mutations by extracting underlying mutational processes}
\usage{
trinuc_mutation_rates(
  cesa,
  cores = 1,
  signature_choice = "cosmic_v3",
  assume_identical_mutational_processes = FALSE,
  sig_averaging_threshold = 50,
  v3_artifact_accounting = TRUE,
  v3_hypermutation_rules = TRUE,
  use_dS_exome2genome = FALSE,
  signatures_to_remove = ""
)
}
\arguments{
\item{cesa}{# CESAnalysis object}

\item{cores}{how many cores to use to process tumor samples in parallel (requires parallel package)}

\item{signature_choice}{"cosmic_v3" (default), "cosmic_v2", or a properly-formatted data frame with of trinucleotide signatures 
(if using cosmic_v3, just leave option default instead of passing your own data frame, or you'll get improper behavior)}

\item{assume_identical_mutational_processes}{(default FALSE) instead of assigning different signature weights to each tumor (reflective of
tumor-specific mutational processes), use well-mutated tumors (those with number of eligible mutations meeting sig_averaging_threshold)
calculate group average signature weights and assign these to all tumors}

\item{sig_averaging_threshold}{Mutational threshold (default 50) that determines which tumors inform the
calculation of group-average signature weightings. When assume_identical_mutational_processes == FALSE (the default), 
these group averages are blended into the signature weightings of tumors with few mutations (those below the threshold).}

\item{v3_artifact_accounting}{when COSMIC v3 signatures associated with sequencing artifacts are detected, renormalizes to isolate true sources of mutational flux.}

\item{v3_hypermutation_rules}{T/F on whether to follow the mutation count rules outlined in https://doi.org/10.1101/322859, the manuscript reported the v3 COSMIC signature set.}

\item{use_dS_exome2genome}{internal dev option (don't use)}

\item{signatures_to_remove}{specify any signatures to exclude from analysis; use suggest_cosmic_v3_signatures_to_remove() for advice on COSMIC v3 signatures}
}
\description{
This function calculates relative rates of trinucleotide-context-specific SNV
mutations within tumors by attributing SNVs to mutational processes represented
in mutation signature sets (such as COSMIC v3). This function currently uses
deconstructSigs to assign mutational signature weightings to tumors. Tumor samples
with targeted sequencing data are assigned the average trinucleotide
mutation rates calculated across all exome/genome data, which means that you need at
least some exome or genome data to run.
}
\details{
To reduce the influence of selection on the estimation of relative trinucleotide mutation
rates, this function only uses non-recurrent SNVs (i.e., those that do not appear in more than one 
sample in the data set).
}
