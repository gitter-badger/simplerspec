################################################################################
## Functions to slice spectra into a set of x axis ranges. A subset of the
## spectra stored in a list-column of a spectral tibble will be selected and
## the x unit axis vector will be reduced accordingly
################################################################################

# Define a set of helper functions ---------------------------------------------

# Helper function to find indices of minimum distances between two vectors
get_idx <- function(x, x_cut) {
  sapply(x, function(x) which.min(abs(x_cut - x)))
}

# Returns a a list of wavenumber position index sequences (type integer) from
# a vector or list of upper and lower slicing boundary values in spectra x
# units (xvalues_cut)
slice_xvalues_idxseq <- function(spc_l, xvalues, xvalues_cut) {
  idx_lim <- lapply(seq_along(xvalues_cut),
    function(i) get_idx(x = xvalues, x_cut = xvalues_cut[i]))
  Map(function(from, to) seq(from, to), idx_lim[[1]], idx_lim[[2]])
}

# Use helper functions in final spectrum x unit slicing function ---------------

#' @title Slice spectra into defined x-axis ranges
#' @description Slice spectra contained in list-column of spectral tibble
#' (data frame). A list of x-axis value ranges can be specified. Spectra are
#' cut based on these ranges.
#' @param spc_tbl Spectral data in a tibble object (classes "tibble_df", "tbl"
#' and "data.frame"). The spectra tibble is expected to contain at least
#' the column  \code{spc} (list-column with spectral matrices stored in a list)
#' and \code{wavenumbers} or \code{wavelengths} (list-column that contains list
#' of x-axis values).
#' @param xunit_lcol Character vector that specifies column name where x-axis
#' axis units are stored within \code{spc_tbl}. Default is \code{"wavenumber"}.
#' @param spc_lcol Character vector that specifies which column (list-column)
#' contains spectra to be sliced. Default is \code{"spc"}.
#' @param xvalues_cut List of numeric vectors that contains upper and lower bounds of respective regions to keep in spectra. The spectral regions outside
#' the \code{xvalues_cut} intervals will be cut out in the output spectra.
#' @return Spectral tibble (data frame with list-columns) with sliced x-axis
#' column and spectral column. Both the x-axis list-column and the spectral
#' tibble list-column only contain data specified within the \code{xvalues_cut}
#' argument (list of numeric vectors).
#' @export
slice_xvalues <- function(spc_tbl, xunit_lcol = "wavenumbers", spc_lcol = "spc",
                          xvalues_cut = NULL) {
  if (is.atomic(xvalues_cut)) xvalues_cut <- list(xvalues_cut)
  if (!is.null(xvalues_cut)) {
    spc_l <- spc_tbl[[spc_lcol]]
    xvalues <- spc_tbl[[xunit_lcol]]
    # Match spectral indices for columns based on xvalue ranges
    idxseq <- lapply(seq_along(xvalues_cut),
      function(i) slice_xvalues_idxseq(
        spc_l = spc_l, xvalues = xvalues, xvalues_cut = xvalues_cut[[i]]))
    idxseq_c <- Reduce(function(x,y) Map(c, x, y), idxseq)
    if (any(sapply(spc_l, data.table::is.data.table))) {
      spc_tbl[[spc_lcol]] <- Map(function(x, idx) x[, idx, with = FALSE],
        spc_l, idxseq_c) # idx is not a column name of any data.table
    } else {
      spc_tbl[[spc_lcol]] <- Map(function(x, idx) x[, idx], spc_l, idxseq_c)
    }
    spc_tbl[[xunit_lcol]] <- Map(function(x, idx) x[idx], xvalues, idxseq_c)
  }
  spc_tbl
}

# Test spectra slicing function:
# tbl_sliced <- slice_xvalues(spc_tbl = spc_tbl,
#   xvalues_cut = list(c(1500, 1024), c(1004, 998)))
