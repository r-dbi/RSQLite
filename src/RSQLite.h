#define STRICT_R_HEADERS
#define R_NO_REMAP

#include "cpp11.hpp"
#include <cpp11/R.hpp>
using namespace cpp11::literals;

#ifndef RSQLite_RSQLite_H
#define RSQLite_RSQLite_H

#ifdef __CLION__
// avoid inclusion of XPtr.h
#define Rcpp_XPtr_h
#endif

// #include <Rcpp.h>
#include <plogr.h>

// Included here because they need -Wno-error,
// which is active only for precompiled headers on my system
#include <boost/container/stable_vector.hpp>
#include <boost/ptr_container/ptr_vector.hpp>

// using namespace Rcpp;

#endif
