library("devtools")

ignore <- c(
  "AnnotationDbi", # deprecation warnings
  "AnnotationForge",
  "AnnotationHub",
  "AnnotationHubData",
  "APSIM",
  "archivist",
  "BatchExperiments", # deprecation warnings
  "BatchJobs", # deprecation warnings
  "bibliospec",
  "biglm",
  "bioassayR", # deprecation warnings
  "caroline",
  "Category", # one fewer warning (Rcpp)
  "ChemmineR",
  "chunked",
  "CITAN",
  "clstutils",
  "CNEr",
  "CollapsABEL",
  "cummeRbund",
  "customProDB",
  "DBI",
  "DECIPHER",
  "dplyr",
  "ecd",
  "emuR",
  "ENCODExplorer",
  "ensembldb",
  "etl",
  "ETLUtils",
  "filehashSQLite",
  "filematrix",
  "freqweights",
  "gcbd",
  "GeneAnswers",
  "GenomicFeatures",
  "Genominator", # one fewer warning (Rcpp)
  "GEOmetadb",
  "GWASTools",
  "imputeMulti",
  "iontree",
  "lumi",
  "macleish",
  "maGUI",
  "manta",
  "marmap",
  "MeSHDbi",
  "metagenomeFeatures",
  "MetaIntegrator",
  "metaseqR",
  "mgsa",
  "miRNAtap",
  "MmPalateMiRNA",
  "MonetDBLite",
  "MUCflights",
  "nutshell",
  "nutshell.bbdb",
  "oai",
  "oce",
  "oligo", # one fewer warning (Rcpp)
  "oligoClasses",
  "OrganismDbi",
  "PAnnBuilder", # one fewer warning (Rcpp)
  "pdInfoBuilder", # one fewer warning (Rcpp)
  "PGA",
  "pitchRx",
  "plethy", # doesn't work with stable version
  "poplite",
  "ProjectTemplate",
  "quantmod",
  "rangeMapper",
  "RecordLinkage", # deprecation warnings
  "recordr",
  "recoup",
  "refGenome",
  "rgrass7",
  "RImmPort",
  "RObsDat",
  "rplexos", # deprecation warnings
  "RQDA",
  "rTRM",
  "rvertnet",
  "scrime",
  "SEERaBomb",
  "seqplots",
  "SGP",
  "smnet",
  "snplist",
  "specL",
  "sqldf", # bug fixed downstream
  "sqliter",
  "SRAdb",
  "SSN",
  "storr",
  "stream",
  "survey",
  "taRifx",
  "tcpl",
  "TFBSTools",
  "tigre", # one fewer warning (Rcpp)
  "trackeR",
  "TSdata",
  "TSsql",
  "TSSQLite",
  "tweet2r",
  "twitteR",
  "UniProt.ws", # one fewer warning (Rcpp)
  "Uniquorn",
  "UPMASK",
  "VariantFiltering",
  "vegdata",
  "vmsbase"
)

ignore2 <- c(
  "AnnotationHubData" # takes more than one hour
)

revdep_check(threads = parallel::detectCores(), bioconductor = TRUE, ignore = NULL)
revdep_check_save_summary()
