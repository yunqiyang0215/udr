#' @rdname ud_fit
#' 
#' @title Fit Ultimate Deconvolution Model
#'
#' @description This function implements "Ultimate Deconvolution", an
#' empirical Bayes method for fitting a multivariate normal means
#' model. This method is closely related to approaches for
#' multivariate density deconvolution (Sarkar \emph{et al}, 2018), so
#' it can also be viewed as a method for multivariate density
#' deconvolution.
#'
#' @details In the Ultimate Deconvolution (UD) model, the
#' m-dimensional observation \eqn{x} is drawn from a mixture of
#' multivariate normals, \eqn{x ~ w_1 N(0, T_1) + ... + w_k N(0,
#' T_k)}, where \eqn{k} is the number of mixture components, the
#' \eqn{w_j}'s are the mixture weights, and each \eqn{T_j = V + U_j}
#' is a covariance matrix. This is the marginal density derived from a
#' model in which \eqn{x} is multivariate normal with mean \eqn{y} and
#' covariance \eqn{V}, and the underlying, or "latent", signal \eqn{y}
#' is in turn modeled by a mixture prior in which each mixture
#' component \eqn{j} is multivariate normal with zero mean and
#' covariance matrix \eqn{U_j}. This model is a useful special case of
#' the "Extreme Deconvolution" (ED) model (Bovy \emph{et al}, 2011).
#'
#' Two variants of the UD model are implemented: one in which the
#' residual covariance V is the same for all data points, and another
#' in which V is different for each data point. In the first case,
#' this covariance matrix may be estimated.
#' 
#' The UD model is fit by expectation-maximization (EM). The
#' \code{control} argument is a list in which any of the following
#' named components will override the default optimization algorithm
#' settings (as they are defined by \code{ud_fit_control_default}):
#' 
#' \describe{
#'
#' \item{\code{weights.update}}{When \code{weights.update = "em"}, the
#' mixture weights are updated via EM; when \code{weights.update =
#' "none"}, the mixture weights are not updated.}
#'
#' \item{\code{resid.update}}{When \code{resid.update = "em"}, the
#' residual covariance matrix is updated via EM; when
#' \code{resid.update = "none", the residual covariance matrix is not
#' updated.}}
#'
#' \item{\code{scaled.update}}{This setting specifies the updates for
#' the scaled prior covariance matrices. Currently, only
#' \code{scaled.update = "none"} is allowed.}
#' 
#' \item{\code{rank1.update}}{This setting specifies the updates for
#' the rank-1 prior covariance matrices. Currently, only
#' \code{rank1.update = "none"} is allowed.}
#' 
#' \item{\code{unconstrained.update}}{This setting determines the
#' updates used to estimate the unconstrained prior covariance
#' matrices. Two variants of EM are implemented: \code{update.U = "ed"},
#' the EM updates described by Bovy \emph{et al} (2011); and
#' \code{update.U = "teem"}, "truncated eigenvalue
#' expectation-maximization", in which the M-step update for each
#' covariance matrix \code{U[[j]]} is solved by truncating the
#' eigenvalues in a spectral decomposition of the unconstrained
#' maximimum likelihood estimate (MLE) of \code{U[j]]}. The latter
#' method provides greater freedom in the updates.}
#'
#' \item{\code{version}}{R and C++ implementations of the model
#' fitting algorithm are provided; these are selected with
#' \code{version = "R"} and \code{version = "Rcpp"}.}
#' 
#' \item{\code{maxiter}}{The upper limit on the number of updates
#' to perform.}
#'
#' \item{\code{tol}}{Convergence tolerance for the optimization; the
#' updates are halted when the largest change in the model parameters
#' between two successive updates is less than \code{tol}.}
#'
#' \item{\code{minval}}{Minimum eigenvalue allowed in the residual
#'   covariance(s) \code{V} and the prior covariance matrices
#'   \code{U}.}}
#'
#' Using this function requires some care; currently only minimal
#' argument checking is performed. See the documentation and examples
#' for guidance.
#'
#' @param fit0 A previous Ultimate Deconvolution model fit. Typically,
#'   this will be an output from \code{\link{ud_init}}, or an output
#'   from a previous call to \code{ud_fit}.
#'
#' @param X The n x m data matrix, in which each row of the matrix is
#'   an m-dimensional data point. The number of rows and columns should
#'   be 2 or more.
#' 
#' @param control A list of parameters controlling the behaviour of
#'   the model fitting and initialization. See \sQuote{Details}.
#'
#' @param verbose When \code{verbose = TRUE}, information about the
#'   algorithm's progress is printed to the console at each
#'   iteration. For interpretation of the columns, see the description
#'   of the \code{progress} return value.
#'
#' @return A list object with the following elements:
#'
#' \item{w}{A vector containing the estimated prior mixture
#'   weights. When \code{control$update.w = "none"}, this will be the
#'   same as the \code{w} provided at input.}
#'
#' \item{U}{A list containing the estimated prior covariance matrices. When
#'   \code{control$update.U = "none"}, this will be the same as the \code{U}
#'   provided at input.}
#' 
#' \item{V}{The estimated residual covariance matrix. When
#'   \code{control$update.S = "none"}, this will be the same as the \code{S}
#'   provided at input.}
#'
#' \item{loglik}{The log-likelihood at the current settings of the
#'   model parameters, \code{w}, \code{U} and \code{S}.}
#'   
#' \item{progress}{A data frame containing detailed information about
#'   the algorithm's progress. The columns of the data frame are:
#'   "iter", the iteration number; "loglik", the log-likelihood at the
#'   current estimates of the model parameters; "delta.w", the largest
#'   change in the mixture weights; "delta.u", the largest change in the
#'   prior covariance matrices; "delta.s", the largest change in the
#'   residual covariance matrix; and "timing", the elapsed time in
#'   seconds (recorded using \code{\link{proc.time}}).}
#'
#' @examples
#' # Simulate data from a UD model.
#' set.seed(1)
#' n <- 4000
#' V <- rbind(c(0.8,0.2),
#'            c(0.2,1.5))
#' U <- list(none   = rbind(c(0,0),
#'                          c(0,0)),
#'           shared = rbind(c(1.0,0.9),
#'                          c(0.9,1.0)),
#'           only1  = rbind(c(1,0),
#'                          c(0,0)),
#'           only2  = rbind(c(0,0),
#'                          c(0,1)))
#' w <- c(0.8,0.1,0.075,0.025)
#' rownames(V) <- c("d1","d2")
#' colnames(V) <- c("d1","d2")
#' X <- simulate_ud_data(n,w,U,V)
#' 
#' # This is the simplest invocation of ud_init.
#' fit1 <- ud_init(X)
#' fit1 <- ud_fit(fit1)
#' summary(fit1)
#' plot(fit1$progress$iter,
#'      max(fit1$progress$loglik) - fit1$progress$loglik + 0.1,
#'      type = "l",col = "dodgerblue",lwd = 2,log = "y",xlab = "iteration",
#'      ylab = "dist to best loglik")
#'
#' # This is a more complex invocation of ud_init that overrides some
#' # of the defaults.
#' fit2 <- ud_init(X,U_scaled = U,n_rank1 = 1,n_unconstrained = 1,V = V)
#' fit2 <- ud_fit(fit2)
#' summary(fit2)
#' plot(fit2$progress$iter,
#'      max(fit2$progress$loglik) - fit2$progress$loglik + 0.1,
#'      type = "l",col = "dodgerblue",lwd = 2,log = "y",xlab = "iteration",
#'      ylab = "dist to best loglik")
#' 
#' @references
#'
#' J. Bovy, D. W. Hogg and S. T. Roweis (2011). Extreme Deconvolution:
#' inferring complete distribution functions from noisy, heterogeneous
#' and incomplete observations. \emph{Annals of Applied Statistics},
#' \bold{5}, 1657–1677. doi:10.1214/10-AOAS439
#'
#' A. Sarkar, D. Pati, A. Chakraborty, B. K. Mallick and R. J. Carroll
#' (2018). Bayesian semiparametric multivariate density deconvolution.
#' \emph{Journal of the American Statistical Association} \bold{113},
#' 401–416. doi:10.1080/01621459.2016.1260467
#'
#' J. Won, J. Lim, S. Kim and B. Rajaratnam (2013).
#' Condition-number-regularized covariance estimation. \emph{Journal
#' of the Royal Statistical Society, Series B} \bold{75},
#' 427–450. doi:10.1111/j.1467-9868.2012.01049.x
#' 
#' @useDynLib udr
#'
#' @importFrom utils modifyList
#' @importFrom Rcpp evalCpp
#' 
#' @export
#' 
ud_fit <- function (fit0, X, control = list(), verbose = TRUE) {
    
  # CHECK & PROCESS INPUTS
  # ----------------------
  # Check input argument "fit0".
  if (!(is.list(fit0) & inherits(fit0,"ud_fit")))
    stop("Input argument \"fit0\" should be an object of class \"ud_fit\",",
         "such as an output of ud_init")
  fit <- fit0
  
  # Check the input data matrix, "X".
  if (missing(X))
    X <- fit$X
  if (!(is.matrix(X) & is.numeric(X)))
    stop("Input argument \"X\" should be a numeric matrix")

  # Get the number of rows (n) and columns (m) of the data matrix, and
  # the number of components in the mixture prior (k).
  n <- nrow(X)
  m <- ncol(X)
  k <- length(fit$U)

  # Extract the "covtype" attribute from the prior covariance matrices.
  covtypes <- sapply(fit$U,function (x) attr(x,"covtype"))
  
  # Check and process the optimization settings.
  control <- modifyList(ud_fit_control_default(),control,keep.null = TRUE)
  if (!is.matrix(fit$V) & control$resid.update != "none") {
    warning("Residual covariance V can only be updated when it is the ",
            "same for all data points; switching to control$resid.update = ",
            "\"none\"")
    control$resid.update <- "none"
  }
  
  # Give an overview of the model fitting.
  if (verbose) {
    cat(sprintf("Performing Ultimate Deconvolution on %d x %d matrix ",n,m))
    cat(sprintf("(udr 0.3-39, \"%s\"):\n",control$version))
    if (is.matrix(fit$V))
      cat("data points are i.i.d. (same V)\n")
    else
      cat("data points are not i.i.d. (different Vs)\n")
    cat(sprintf("prior covariances: %d scaled, %d rank-1, %d unconstrained\n",
                sum(covtypes == "scaled"),
                sum(covtypes == "rank1"),
                sum(covtypes == "unconstrained")))
    cat(sprintf(paste("prior covariance updates: %s (scaled), %s (rank-1),",
                      "%s (unconstrained)\n"),
                control$scaled.update,
                control$rank1.update,
                control$unconstrained.update))
    cat(sprintf("mixture weights update: %s\n",control$weights.update))
    if (is.matrix(fit$V))
      cat(sprintf("residual covariance update: %s\n",control$resid.update))
    cat(sprintf("max %d updates, conv tol %0.1e\n",
                control$maxiter,control$tol))
  }
  
  # RUN UPDATES
  # -----------
  if (verbose)
    cat("iter          log-likelihood |w - w'| |U - U'| |V - V'|\n")
  if (is.list(fit$V))
    fit$V <- simplify2array(fit$V)
  fit$U <- simplify2array(fit$U)
  fit <- ud_fit_main_loop(X,fit$w,fit$U,fit$V,covtypes,control,verbose)
  
  # Output the updated model. Some attributes such as row and column
  # names may be missing and need to be added back.
  fit$progress <- rbind(fit0$progress,fit$progress)
  fit$loglik <- loglik_ud(X,fit$w,fit$U,fit$V,control$version)
  fit$X <- X
  fit$U <- array2list(fit$U)
  if (is.matrix(fit$V)) {
    rownames(fit$V) <- colnames(X)
    colnames(fit$V) <- colnames(X)
  } else
    fit$V <- array2list(fit$V)
  for (i in 1:k) {
    rownames(fit$U[[i]]) <- colnames(X)
    colnames(fit$U[[i]]) <- colnames(X)
    attr(fit$U[[i]],"covtype") <- attr(fit0$U[[i]],"covtype")
  }
  names(fit$w) <- names(fit0$U)
  names(fit$U) <- names(fit0$U)
  class(fit) <- c("ud_fit","list")
  return(fit)
}

# This implements the core part of ud_fit.
ud_fit_main_loop <- function (X, w, U, V, covtypes, control, verbose) {

  # Get the number of components in the mixture prior.
  k <- length(w)
  
  # Set up data structures used in the loop below.
  progress <- as.data.frame(matrix(0,control$maxiter,6))
  names(progress) <- c("iter","loglik","delta.w","delta.v","delta.u","timing")
  progress$iter <- 1:control$maxiter
  
  # Iterate the EM updates.
  for (iter in 1:control$maxiter) {
    t1 <- proc.time()

    # E-step
    # ------
    # Compute the n x k matrix of posterior mixture assignment
    # probabilities given current estimates of the model parameters.
    P <- compute_posterior_probs(X,w,U,V,control$version)

    # M-step
    # ------
    # Update the residual covariance matrix.
    Vnew <- V
    if (is.matrix(V))
      Vnew <- update_resid_covariance(X,U,V,P,control$resid.update,
                                      control$version)
    
    # Update the scaled prior covariance matrices.
    Unew <- update_prior_covariances(X,U,V,P,covtypes,control)
    
    # Update the mixture weights.
    wnew <- update_mixture_weights_em(P,control$weights.update)
  
    # Update the "progress" data frame with the log-likelihood and
    # other quantities, and report the algorithm's progress to the
    # console if requested.
    loglik <- loglik_ud(X,wnew,Unew,Vnew,control$version)
    dw <- max(abs(wnew - w))
    dU <- max(abs(Unew - U))
    if (is.matrix(V))
      dV <- max(abs(Vnew - V))
    else
      dV <- 0
    t2 <- proc.time()
    progress[iter,"loglik"]  <- loglik
    progress[iter,"delta.w"] <- dw 
    progress[iter,"delta.u"] <- dU 
    progress[iter,"delta.v"] <- dV 
    progress[iter,"timing"]  <- t2["elapsed"] - t1["elapsed"]
    if (verbose)
      cat(sprintf("%4d %+0.16e %0.2e %0.2e %0.2e\n",iter,loglik,dw,dU,dV))

    # Apply the parameter updates, and check convergencce.
    w <- wnew
    U <- Unew
    V <- Vnew
    if (max(dw,dU,dV) < control$tol)
      break
  }

  # Output the parameters of the updated model, and a record of the
  # algorithm's progress over time.
  return(list(w = w,U = U,V = V,progress = progress[1:iter,]))
}

#' @rdname ud_fit
#'
#' @export
#' 
ud_fit_control_default <- function()
  list(weights.update       = "em",   # "em" or "none"
       scaled.update        = "em",   # "em" or "none"
       rank1.update         = "teem", # "teem" or "none"
       unconstrained.update = "ed",   # "ed", "teem" or "none"
       resid.update         = "em",   # "em" or "none"
       version              = "R",    # "R" or "Rcpp"
       maxiter              = 20,
       minval               = -1e-8,
       tol                  = 1e-6)
