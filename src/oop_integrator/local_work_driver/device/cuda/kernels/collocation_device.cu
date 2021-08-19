#include <gauxc/util/div_ceil.hpp>
#include <gauxc/util/cuda_util.hpp>
#include "exceptions/cuda_exception.hpp"
#include <gauxc/xc_task.hpp>

#include "device/cuda/kernels/collocation_masked_kernels.hpp"
#include "device/cuda/kernels/collocation_masked_combined_kernels.hpp"

#include "device_specific/cuda_device_constants.hpp"

namespace GauXC {

 
template <typename T>
void eval_collocation_masked(
  size_t          nshells,
  size_t          nbf,
  size_t          npts,
  const Shell<T>* shells_device,
  const size_t*   mask_device,
  const size_t*   offs_device,
  const T*        pts_device,
  T*              eval_device,
  cudaStream_t    stream
) {

  auto nmax_threads = util::cuda_kernel_max_threads_per_block( 
    collocation_device_masked_kernel<T>
  );
  auto max_warps_per_thread_block = nmax_threads / cuda::warp_size;

  dim3 threads(cuda::warp_size, max_warps_per_thread_block, 1);
  dim3 blocks( util::div_ceil( npts,    threads.x ),
               util::div_ceil( nshells, threads.y ) );

  collocation_device_masked_kernel<T>
    <<<blocks, threads, 0, stream>>>
    ( nshells, nbf, npts, shells_device, mask_device,
      offs_device, pts_device, eval_device );

}
 
template             
void eval_collocation_masked(
  size_t               nshells,
  size_t               nbf,
  size_t               npts,
  const Shell<double>* shells_device,
  const size_t*        mask_device,
  const size_t*        offs_device,
  const double*        pts_device,
  double*              eval_device,
  cudaStream_t         stream
);




template <typename T>
void eval_collocation_masked_combined(
  size_t        ntasks,
  size_t        npts_max,
  size_t        nshells_max,
  Shell<T>*     shells_device,
  XCDeviceTask* device_tasks,
  cudaStream_t  stream
) {

  auto nmax_threads = util::cuda_kernel_max_threads_per_block( 
    collocation_device_masked_combined_kernel<T>
  );

  auto max_warps_per_thread_block = nmax_threads / cuda::warp_size;
  dim3 threads(cuda::warp_size, max_warps_per_thread_block, 1);
  dim3 blocks( util::div_ceil( npts_max,    threads.x ),
               util::div_ceil( nshells_max, threads.y ),
               ntasks );

  collocation_device_masked_combined_kernel<T>
    <<<blocks, threads, 0, stream>>>
    ( ntasks, shells_device, device_tasks );
     
}

template
void eval_collocation_masked_combined(
  size_t                ntasks,
  size_t                npts_max,
  size_t                nshells_max,
  Shell<double>*        shells_device,
  XCDeviceTask* device_tasks,
  cudaStream_t          stream
);











template <typename T>
void eval_collocation_masked_deriv1(
  size_t          nshells,
  size_t          nbf,
  size_t          npts,
  const Shell<T>* shells_device,
  const size_t*   mask_device,
  const size_t*   offs_device,
  const T*        pts_device,
  T*              eval_device,
  T*              deval_device_x,
  T*              deval_device_y,
  T*              deval_device_z,
  cudaStream_t    stream
) {

  auto nmax_threads = util::cuda_kernel_max_threads_per_block( 
    collocation_device_masked_combined_kernel<T>
  );

  auto max_warps_per_thread_block = nmax_threads / cuda::warp_size;
  dim3 threads(cuda::warp_size, max_warps_per_thread_block, 1);
  dim3 blocks( util::div_ceil( npts,    threads.x ),
               util::div_ceil( nshells, threads.y ) );

  collocation_device_masked_kernel_deriv1<T>
    <<<blocks, threads, 0, stream>>>
    ( nshells, nbf, npts, shells_device, mask_device, offs_device,
      pts_device, eval_device, deval_device_x, deval_device_y,
      deval_device_z );

}

template
void eval_collocation_masked_deriv1(
  size_t               nshells,
  size_t               nbf,
  size_t               npts,
  const Shell<double>* shells_device,
  const size_t*        mask_device,
  const size_t*        offs_device,
  const double*        pts_device,
  double*              eval_device,
  double*              deval_device_x,
  double*              deval_device_y,
  double*              deval_device_z,
  cudaStream_t         stream
);
















template <typename T>
void eval_collocation_masked_combined_deriv1(
  size_t        ntasks,
  size_t        npts_max,
  size_t        nshells_max,
  Shell<T>*     shells_device,
  XCDeviceTask* device_tasks,
  cudaStream_t  stream
) {

  auto nmax_threads = util::cuda_kernel_max_threads_per_block( 
    collocation_device_masked_combined_kernel_deriv1<T>
  );

  dim3 threads(cuda::warp_size, nmax_threads/cuda::warp_size, 1);
  dim3 blocks( util::div_ceil( npts_max,    threads.x ),
               util::div_ceil( nshells_max, threads.y ),
               ntasks );

  collocation_device_masked_combined_kernel_deriv1<T>
    <<<blocks, threads, 0, stream>>>
    ( ntasks, shells_device, device_tasks );
     
}

template
void eval_collocation_masked_combined_deriv1(
  size_t                ntasks,
  size_t                npts_max,
  size_t                nshells_max,
  Shell<double>*        shells_device,
  XCDeviceTask* device_tasks,
  cudaStream_t          stream
);













} // namespace GauXC
