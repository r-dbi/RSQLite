#ifndef RSQLite_RSQLite_H
#define RSQLite_RSQLite_H

#include "cpp11.hpp"
#include <cpp11/R.hpp>

// CRAN request
#ifndef BOOST_NO_AUTO_PTR
#define BOOST_NO_AUTO_PTR
#endif

// Included here because they need -Wno-error,
// which is active only for precompiled headers on my system
#include <boost/container/stable_vector.hpp>
#include <boost/ptr_container/ptr_vector.hpp>

#endif
