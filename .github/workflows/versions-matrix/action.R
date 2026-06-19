# Determine active versions of R to test against
tags <- xml2::read_html("https://svn.r-project.org/R/tags/")

bullets <-
  tags |>
  xml2::xml_find_all("//li") |>
  xml2::xml_text()

version_bullets <- grep("^R-([0-9]+-[0-9]+-[0-9]+)/$", bullets, value = TRUE)
versions <- unique(gsub("^R-([0-9]+)-([0-9]+)-[0-9]+/$", "\\1.\\2", version_bullets))

r_release <- head(sort(as.package_version(versions), decreasing = TRUE), 5)

deps <- desc::desc_get_deps()
r_crit <- deps$version[deps$package == "R"]
if (length(r_crit) == 1) {
  min_r <- as.package_version(gsub("^>= ([0-9]+[.][0-9]+)(?:.*)$", "\\1", r_crit))
  r_release <- r_release[r_release >= min_r]
}

r_versions <- c("devel", as.character(r_release))

macos <- data.frame(os = "macos-latest", r = r_versions[2:3])
windows <- data.frame(os = "windows-latest", r = r_versions[1:3])
linux_devel <- data.frame(os = "ubuntu-24.04", r = r_versions[1], `http-user-agent` = "release", check.names = FALSE)
linux <- data.frame(os = "ubuntu-24.04", r = r_versions[-1])
covr <- data.frame(os = "ubuntu-24.04", r = r_versions[2], covr = "true", desc = "with covr")

# Compile-only builds of the package's native code under non-default language
# standards, to catch portability problems ahead of R changing its defaults.
# These only build the package (no R CMD check), and are added only when the
# package actually ships the relevant C or C++ sources.
#
# Maintaining these as standards evolve:
#   * `c_stds` / `cxx_stds` below list the standards to compile under, as
#     (human label, `-std` value). Use the GNU dialect ("gnu*") so they match
#     the standards R itself uses, not strict ISO ("c*").
#   * When compilers gain a newer standard, add it here, e.g. append
#     list("C++26", "gnu++26") to `cxx_stds`, or list("C23", "gnu2x") /
#     list("C2Y", "gnu2y") to `c_stds`. Keep `c_stds` ordered oldest-first and
#     keep each entry's `year` accurate (it is compared against the C floor
#     below). Drop a standard once it is no longer worth testing (e.g. once it
#     becomes R's default and is covered by the regular check jobs).
#   * The C entries honor a C-standard floor declared in DESCRIPTION's
#     SystemRequirements: any standard older than the declared minimum is
#     dropped, since the package does not claim to support it. To change which
#     C standards are tested, edit SystemRequirements (e.g. add "USE_C99" to
#     stop testing C90), not this file. There is no analogous C++ gate; add one
#     the same way if you start honoring a declared "C++NN" minimum.
native_sources <- if (dir.exists("src")) {
  list.files("src", pattern = "[.](c|cc|cpp|cxx)$", recursive = TRUE)
} else {
  character()
}
has_c_sources <- any(grepl("[.]c$", native_sources))
has_cxx_sources <- any(grepl("[.](cc|cpp|cxx)$", native_sources))

# Older C standards to compile under, oldest first. `year` is used only to
# compare against the SystemRequirements floor.
c_stds <- data.frame(
  label = c("C90", "C99", "C17"),
  std = c("gnu90", "gnu99", "gnu17"),
  year = c(1990, 1999, 2017),
  stringsAsFactors = FALSE
)
# Newest C++ standard to compile under.
cxx_stds <- data.frame(
  label = "C++23",
  std = "gnu++23",
  stringsAsFactors = FALSE
)

# Honor a C-standard floor from SystemRequirements and drop the C standards the
# package does not claim to support. R documents the USE_C90/USE_C99/USE_C11/
# USE_C17/USE_C23 tokens; the bare "C99" form is also accepted. "C++NN" tokens
# are deliberately not matched. The highest declared standard wins.
sysreq <- read.dcf("DESCRIPTION")[1, ]["SystemRequirements"]
c_floor_year <- 0
if (!is.na(sysreq)) {
  toks <- regmatches(
    sysreq,
    gregexpr("(?<![+[:alnum:]])C(?:90|99|11|17|23)\\b", sysreq, perl = TRUE)
  )[[1]]
  if (length(toks) > 0) {
    years <- c(C90 = 1990, C99 = 1999, C11 = 2011, C17 = 2017, C23 = 2023)
    c_floor_year <- max(years[toks])
  }
}
c_stds <- c_stds[c_stds$year >= c_floor_year, , drop = FALSE]

# Build these against the newest released R (widest standard support).
std_r <- r_versions[2]
std_list <- list()
if (has_c_sources && nrow(c_stds) > 0) {
  std_list <- c(std_list, list(data.frame(
    os = "ubuntu-24.04", r = std_r, lang = "c",
    std = c_stds$std,
    desc = paste0("compile-only ", c_stds$label),
    stringsAsFactors = FALSE
  )))
}
if (has_cxx_sources && nrow(cxx_stds) > 0) {
  std_list <- c(std_list, list(data.frame(
    os = "ubuntu-24.04", r = std_r, lang = "cxx",
    std = cxx_stds$std,
    desc = paste0("compile-only ", cxx_stds$label),
    stringsAsFactors = FALSE
  )))
}

include_list <- c(list(macos, windows, linux_devel, linux, covr), std_list)

if (file.exists(".github/versions-matrix.R")) {
  custom <- source(".github/versions-matrix.R")$value
  if (is.data.frame(custom)) {
    custom <- list(custom)
  }
  include_list <- c(include_list, custom)
}

print(include_list)

filter <- read.dcf("DESCRIPTION")[1, ]["Config/gha/filter"]
if (!is.na(filter)) {
  filter_expr <- parse(text = filter)[[1]]
  subset_fun_expr <- bquote(function(x) subset(x, .(filter_expr)))
  subset_fun <- eval(subset_fun_expr)
  include_list <- lapply(include_list, subset_fun)
  print(include_list)
}

to_json <- function(x) {
  if (nrow(x) == 0) return(character())
  parallel <- vector("list", length(x))
  for (i in seq_along(x)) {
    parallel[[i]] <- paste0('"', names(x)[[i]], '":"', x[[i]], '"')
  }
  paste0("{", do.call(paste, c(parallel, sep = ",")), "}")
}

configs <- unlist(lapply(include_list, to_json))
json <- paste0('{"include":[', paste(configs, collapse = ","), "]}")

if (Sys.getenv("GITHUB_OUTPUT") != "") {
  writeLines(paste0("matrix=", json), Sys.getenv("GITHUB_OUTPUT"))
}
writeLines(json)
