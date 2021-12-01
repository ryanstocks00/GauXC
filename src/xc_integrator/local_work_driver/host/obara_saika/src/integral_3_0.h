#ifndef __MY_INTEGRAL_3_0
#define __MY_INTEGRAL_3_0

#include "integral_3_0.h"

void integral_3_0(size_t npts,
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
