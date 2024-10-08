#' Print method for \code{idm} objects
#' 
#' Print a summary of a fitted illness-death model 
#' 
#' 
#' @param x Class \code{idm} object, i.e. the result of a call to the
#' \code{\link{idm}} function with \code{intensities}="Weib".
#' @param conf.int The level of confidence for the hazard ratios. The default is \code{0.95}.
#' @param digits Number of digits to print.
#' @param coef If true print coefficient and hazard ratio
#' @param pvalDigits Number of digits to print for p-values.
#' @param eps Passed to \code{format.pval}.
#' @param \dots Not used.
#' @author Celia Touraine <Celia.Touraine@@isped.u-bordeaux2.fr>, Thomas A. Gerds <tag@@biostat.ku.dk> 
#' @seealso \code{\link{summary.idm}}, \code{\link{plot.idm}}
#' @keywords methods
#' @examples
#' 
#' \dontrun{
#' data(Paq1000)
#' library(prodlim)
#' fit.splines <-  idm(formula02=Hist(time=t,event=death,entry=t0)~certif,
#' 		formula01=Hist(time=list(l,r),event=dementia)~certif,
#'                 formula12=~1,
#'                 method="Splines",
#' 		data=Paq1000)
#' print(fit.splines)
#' 
#' }
#' @useDynLib SmoothHazardoptim9
#' @export
print.idm <- function(x,conf.int=.95,digits=4,pvalDigits=4,eps=0.0001,coef=F,...){
    # {{{  call
    cl <- x$call
    if(is.null(x$BIC)){
      n_model<-1
    }else{
      n_model<-length(x$BIC)
    }
    
    if(!is.null(x$modelPar)){
     method<-"weib"}else{method<-"splines"}
    
    
    cat("Call:\n")
    dput(cl)
    cat("\n")
    # }}}
    # {{{ number of subjects etc
    cat("Illness-death regression model using",
        ifelse(method=="splines"," M-spline approximations","Weibull parametrization"),
        "\nto estimate the baseline transition intensities.\n")
    cat("\n")
    cat("number of subjects: ", x$N,"\n")
    cat("number of events '0 -> 1': ", x$events1,"\n")
    cat("number of events '0 -> 2' or '0 -> 1 -> 2': ", x$events2,"\n")
    cat("number of covariates: ", x$NC,"\n")
    # }}}
    # {{{ convergence
    # FIXME: what is the difference between maximum number of iterations reached and
    #        model did not converge?

    if( sum(x$converged!=1)>0 & length(x$converged)==1){
        warning("The model did not converge.","\n")
        switch(as.character(x$converged[1]),
               "2"={ warning("Maximum number of iterations reached. \n",call.=FALSE)},
               "3"={ warning("Fisher information matrix non-positive definite. \n",call.=FALSE)})
    }else{
        if(length(x$converged)==1 ){
            cat("The model did converge. \n")
            cat("Log-likelihood : ",x$loglik[1], "\n")
            cat("----\nModel converged.\n")
            cat("number of iterations: ", x$niter,"\n")
            cat("convergence criteria: parameters=", signif(x$cv$cb,2), "\n")
            cat("                    : likelihood=", signif(x$cv$ca,2), "\n") 
            cat("                    : second derivatives=", signif(x$cv$rdm,2), "\n")
  
        }else{
          if(sum(x$converged!=1)>0){
            warning(paste0("Among the ",n_model," models, ",sum(x$converged!=1)," did not converged"),"\n")
            warning(paste0("Maximum number of iterations reached for ",sum(x$converged==2)," models. \n"))
          }
          ca.beta<-apply(x$cv$ca.beta,MARGIN=2,FUN=function(x){x<-na.omit(x) 
          return(x[length(x)])})
          ca.spline<-apply(x$cv$ca.spline,MARGIN=2,FUN=function(x){x<-na.omit(x) 
          return(x[length(x)])})
          cb<-apply(x$cv$cb,MARGIN=2,FUN=function(x){x<-na.omit(x) 
          return(abs(x[length(x)]-x[length(x)-1]))})
          cat("All ",n_model," models did converge. \n")
          
          for(k in 1:n_model){
            cat("------------ Model ",k," ------------ \n")
            cat("Log-likelihood : ",x$loglik[k], "\n")
            cat("number of iterations: ", x$niter[k],"\n")
            cat("convergence criteria: parameters beta=", ca.beta[k], "\n")
            cat("                    : parameters base risk=", ca.spline[k], "\n") 
            cat("                    : likelihood=", cb[k], "\n")
          }
        }
          

    # }}}
    # {{{ Spline: baseline parameters
    if (method=="splines"){
        n_spline<-x$nknots01+x$nknots02+x$nknots12+6
        splinepars <- data.frame("transition01"=x$nknots01,
                                 "transition02"=x$nknots02,
                                 "transition12"=x$nknots12)
        rownames(splinepars) <- c("knots")
        cat("\n")
        cat("Splines parameters:\n")
        print(splinepars,row.names=TRUE)
    
        
        # }}}
        # {{{ Weibull: baseline parameters
    }
        # }}}
        # {{{ Weibull: baseline parameter
    if (method=="weib"){
      n_spline<-6
        cat("Parameters of the Weibull distributions: 'S(t) = exp(-(b*t)^a)'\n")
      if(n_model==1){
        wpars <- matrix(x$modelPar^2,nrow=2)
        dimnames(wpars) <- list(c("shape (a)","scale (b)"),
                                c("transition 0 -> 1",
                                  "transition 0 -> 2",
                                  "transition 1 -> 2"))
        prmatrix(wpars)
      }else{
        rownames(x$modelPar)<-rep(c("shape (a)","scale (b)"),3)
        cat("transition 0 ->1 : \n")
        print(x$modelPar[1:2,]^2,row.names=TRUE)
        cat("\n")
        cat("transition 0 ->2 : \n")
        print(x$modelPar[3:4,]^2,row.names=TRUE)
        cat("\n")
        cat("transition 1 ->2 : \n")
        print(x$modelPar[5:6,]^2,row.names=TRUE)
        cat("\n")
        
      }
    }
    # }}}
    # {{{  Regression coefficients
    if(sum(x$NC)>0 & coef==T){
      
      if(n_model==1){
        
        if(x$converged==1){
          se<-sqrt(diag(x$V[(n_spline+1):(dim(x$V)[1]),(n_spline+1):(dim(x$V)[1])]))
          z <- abs(qnorm((1 + conf.int)/2))
          wald <- (x$coef/se)**2
        coefmat <- data.frame("coef"=format(round(x$coef,digits)),
                              "SE coef"=format(round(se,digits)),
                              "exp(coef)"=format(round(x$HR,digits)),
                              "CI"=paste0("[",
                                          format(round(exp(x$coef - z * se),2)),
                                          ";",
                                          format(round(exp(x$coef + z * se),2)),
                                          "]"),
                              ## "Wald"=format(wald,digits),
                              "p-value"=format.pval(1 - pchisq(wald, 1),digits=pvalDigits,eps=eps),
                              
                              check.names=FALSE)
        }else{
          coefmat <- data.frame("coef"=format(round(x$coef,digits)),
                                "exp(coef)"=format(round(x$HR,digits)),
                                check.names=FALSE)
        }
        coefmat <- cbind(Factor=names(x$coef),coefmat)
        coeflist <- split(coefmat,rep(c("transition 0 -> 1","transition 0 -> 2","transition 1 -> 2"),x$NC))
        cat("\n\nRegression coefficients:\n\n")
        print(coeflist)
        
      }else{

        for(k in 1:n_model){
          cat("------------ Model ",k," ------------ \n")
          coefmat <- data.frame("coef"=format(round(x$coef[,k],digits)),
                                "exp(coef)"=format(round(x$HR[,k],digits)))
          coefmat <- cbind(Factor=rownames(x$coef),coefmat)
          coeflist <- split(coefmat,rep(c("transition 0 -> 1","transition 0 -> 2","transition 1 -> 2"),x$NC))
          cat("\n\n Regression coefficients:\n\n")
          print(coeflist)
        }
      }
    }
    }
}
        
        

