% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ml_objective.R
\name{ml_objective}
\alias{ml_objective}
\title{ml_objective}
\usage{
ml_objective(
  gamma,
  tumor_stages,
  tumors_without_gene_mutated,
  tumors_with_pos_mutated,
  variant,
  specific_mut_rates,
  modifier = 0
)
}
\arguments{
\item{gamma}{A selection intensity at which to calculate the likelihood}

\item{tumor_stages}{an environment with keys = tumor names, values = stage of tumor}

\item{tumors_without_gene_mutated}{list of tumors without any mutation in the gene of the variant}

\item{tumors_with_pos_mutated}{list of tumors with the specific variant in question}

\item{variant}{the unique mutation whose selection intensity is being determined}

\item{specific_mut_rates}{A matrix of site and tumor specific mutation rates where the rows correspond to tumors and the columns to variants (produced by mutation_rate_calc)}
}
\value{
A log likelihood value
}
\description{
Objective function that we will be optimizing in order to find the site specific selection intensity that maximizes the likelihood of each tumor having a mutation or not, where the mutation rates are site and tumor specific.
}
\keyword{internal}
