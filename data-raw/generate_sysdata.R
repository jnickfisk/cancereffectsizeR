prev_dir = setwd(system.file("data-raw", package = "cancereffectsizeR"))

source("build_codon_point_mutation_dict.R")
codon_point_mutation_dict = build_codon_point_mutation_dict()

source("build_deconstructSigs_stuff.R")
deconstructSigs_trinuc_string = build_deconstructSigs_trinuc_string()
trinuc_translator = build_trinuc_translator(deconstructSigs_trinuc_string)

cosmic_v3_signature_metadata = data.table::fread("COSMIC_v3_signature_metadata.txt")
usethis::use_data(codon_point_mutation_dict, deconstructSigs_trinuc_string, 
                  trinuc_translator, cosmic_v3_signature_metadata, 
                  internal = TRUE, overwrite = TRUE)
setwd(prev_dir)
