% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/optimize_gamma.R
\name{optimize_gamma}
\alias{optimize_gamma}
\title{Calculate selection intensity}
\usage{
optimize_gamma(
  MAF_input,
  eligible_tumors,
  progressions,
  samples,
  gene,
  variant,
  specific_mut_rates
)
}
\arguments{
\item{MAF_input}{A data frame that includes columns "Unique_patient_identifier", "Gene_name", and "unique_variant_ID_AA"}

\item{eligible_tumors}{a vector of tumors we are calculating the likelihood across (excludes tumors without coverage at the variant site)}

\item{progressions}{ordered progressions}

\item{gene}{The gene we want to look at}

\item{variant}{The variant we want to look at}

\item{specific_mut_rates}{A matrix of site and tumor specific mutation rates where the rows correspond to tumors and the columns to variants (produced by mutation_rate_calc)}
}
\value{
The optimal selection intensity for the gene and variant that maximizes the likelihood of the observations
}
\description{
Actual function to find the site specific selection intensity that maximizes the likelihood of each tumor being mutated or not. Uses site and tumor specific mutation rates. Uses Brent 1 dimensional optimization technique.optimize_gamma
}
\keyword{internal}
