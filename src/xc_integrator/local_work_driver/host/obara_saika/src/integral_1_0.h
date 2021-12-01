#ifndef __MY_INTEGRAL_1_0
#define __MY_INTEGRAL_1_0

#include "integral_1_0.h"

void integral_1_0(size_t npts,
                  shell_pair shpair,
                  double *points,
                  double *Xi,
                  double *Xj,
                  int ldX,
                  double *Gi,
                  double *Gj,
                  int ldG, 
                  double *weights);

#endif
