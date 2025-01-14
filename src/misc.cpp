#include "misc.h"

using namespace arma;

// FUNCTION DEFINITIONS
// --------------------
// Scale each row A[i,] by b[i].
void scale_rows (mat& A, const vec& b) {
  vec c = b;
  A.each_col() %= c;
}

// Return the "softmax" of vector x, y(i) = exp(x(i))/sum(exp(x)), in
// a way that guards against numerical underflow or overflow. The
// return value is a vector with entries that sum to 1.
rowvec softmax (const rowvec& x) {
  rowvec y = exp(x - max(x));
  y /= sum(y);
  return y;
}

// Replace x with x/sum(x), but take care of the special case when all
// the entries are zero, in which case return the vector of all 1/n,
// where n is the length of x.
void safenormalize (vec& x) {
  unsigned int n = x.n_elem;
  if (sum(x) <= 0)
    x.fill(1/n);
  else
    x = x/sum(x);
}

// Return the cross-product of matrix X, i.e., X'*X.
mat crossprod (const mat& X) {
  return trans(X) * X;
}

// Compute the log-probability of x, where x is multivariate normal
// with mean zero and covariance matrix S. Input argument should be L
// be the Cholesky factor of S; L = chol(S,"lower").
double ldmvnorm (const vec& x, const mat& L) {
  double d = norm(solve(L,x),2);
  return -d*d/2 - sum(log(sqrt(2*M_PI)*L.diag()));
}

