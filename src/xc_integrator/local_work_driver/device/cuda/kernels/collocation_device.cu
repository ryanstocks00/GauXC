#include <gauxc/util/div_ceil.hpp>
#include "device_specific/cuda_util.hpp"
#include "exceptions/cuda_exception.hpp"
#include <gauxc/xc_task.hpp>

#include "device/common/collocation_device.hpp"
#include "device/cuda/kernels/collocation_masked_kernels.hpp"
#include "device/cuda/kernels/collocation_masked_combined_kernels.hpp"
#include "device/cuda/kernels/collocation_shell_to_task_kernels.hpp"

#include "device_specific/cuda_device_constants.hpp"

namespace GauXC {

 
template <typename T>
void eval_collocation_masked(
  size_t            nshells,
  size_t            nbf,
  size_t            npts,
  const Shell<T>*   shells_device,
  const size_t*     mask_device,
  const size_t*     offs_device,
  const T*          pts_device,
  T*                eval_device,
  type_erased_queue queue
) {

  cudaStream_t stream = queue.queue_as<util::cuda_stream>() ;

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
  type_erased_queue    queue
);




template <typename T>
void eval_collocation_masked_combined(
  size_t            ntasks,
  size_t            npts_max,
  size_t            nshells_max,
  Shell<T>*         shells_device,
  XCDeviceTask*     device_tasks,
  type_erased_queue queue
) {

  cudaStream_t stream = queue.queue_as<util::cuda_stream>() ;

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
  size_t            ntasks,
  size_t            npts_max,
  size_t            nshells_max,
  Shell<double>*    shells_device,
  XCDeviceTask*     device_tasks,
  type_erased_queue queue
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
  type_erased_queue queue
) {

  cudaStream_t stream = queue.queue_as<util::cuda_stream>() ;

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
  type_erased_queue    queue
);
















template <typename T>
void eval_collocation_masked_combined_deriv1(
  size_t        ntasks,
  size_t        npts_max,
  size_t        nshells_max,
  Shell<T>*     shells_device,
  XCDeviceTask* device_tasks,
  type_erased_queue queue
) {

  cudaStream_t stream = queue.queue_as<util::cuda_stream>() ;

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
  type_erased_queue queue
);






























uint32_t max_threads_shell_to_task_collocation( int32_t l, bool pure ) {
  if( pure ) {
    switch(l) {
      case 0: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_cartesian_0 );
      case 1: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_spherical_1 );
      case 2: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_spherical_2 );
      case 3: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_spherical_3 );
    }
  } else {
    switch(l) {
      case 0: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_cartesian_0 );
      case 1: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_cartesian_1 );
      case 2: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_cartesian_2 );
      case 3: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_cartesian_3 );
    }
  }
  return 0;
}

template <typename... Args>
void dispatch_shell_to_task_collocation( cudaStream_t stream, int32_t l, bool pure, int32_t nshells, Args&&... args ) {
  dim3 threads = max_threads_shell_to_task_collocation(l,pure);
  dim3 block(1, nshells);
  if( pure ) {
    switch(l) {
      case 0:
        collocation_device_shell_to_task_kernel_cartesian_0<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
      case 1:
        collocation_device_shell_to_task_kernel_spherical_1<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
      case 2:
        collocation_device_shell_to_task_kernel_spherical_2<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
      case 3:
        collocation_device_shell_to_task_kernel_spherical_3<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
    }
  } else {
    switch(l) {
      case 0:
        collocation_device_shell_to_task_kernel_cartesian_0<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
      case 1:
        collocation_device_shell_to_task_kernel_cartesian_1<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
      case 2:
        collocation_device_shell_to_task_kernel_cartesian_2<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
      case 3:
        collocation_device_shell_to_task_kernel_cartesian_3<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
    }
  }
}


void eval_collocation_shell_to_task(
  uint32_t           nshells,
  uint32_t           L,
  uint32_t           pure,
  ShellToTaskDevice* shell_to_task_device,
  XCDeviceTask*      device_tasks,
  type_erased_queue  queue 
) {

  cudaStream_t stream = queue.queue_as<util::cuda_stream>() ;

  dispatch_shell_to_task_collocation( stream, L, pure, nshells, 
    shell_to_task_device, device_tasks );


}


uint32_t max_threads_shell_to_task_collocation_gradient( int32_t l, bool pure ) {
  if( pure ) {
    switch(l) {
      case 0: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_cartesian_gradient_0 );
      case 1: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_spherical_gradient_1 );
      case 2: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_spherical_gradient_2 );
      case 3: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_spherical_gradient_3 );
    }
  } else {
    switch(l) {
      case 0: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_cartesian_gradient_0 );
      case 1: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_cartesian_gradient_1 );
      case 2: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_cartesian_gradient_2 );
      case 3: return util::cuda_kernel_max_threads_per_block( collocation_device_shell_to_task_kernel_cartesian_gradient_3 );
    }
  }
  return 0;
}

template <typename... Args>
void dispatch_shell_to_task_collocation_gradient( cudaStream_t stream, int32_t l, bool pure, uint32_t nshells, Args&&... args ) {

  //dim3 threads = max_threads_shell_to_task_collocation(l,pure);
  //uint32_t nwarp_per_block = threads.x / cuda::warp_size;
  //dim3 block(32, 1);
  dim3 threads = max_threads_shell_to_task_collocation(l,pure);
  dim3 block(1, nshells);

  if( pure ) {
    switch(l) {
      case 0:
        collocation_device_shell_to_task_kernel_cartesian_gradient_0<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
      case 1:
        collocation_device_shell_to_task_kernel_spherical_gradient_1<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
      case 2:
        collocation_device_shell_to_task_kernel_spherical_gradient_2<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
      case 3:
        collocation_device_shell_to_task_kernel_spherical_gradient_3<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
    }
  } else {
    switch(l) {
      case 0:
        collocation_device_shell_to_task_kernel_cartesian_gradient_0<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
      case 1:
        collocation_device_shell_to_task_kernel_cartesian_gradient_1<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
      case 2:
        collocation_device_shell_to_task_kernel_cartesian_gradient_2<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
      case 3:
        collocation_device_shell_to_task_kernel_cartesian_gradient_3<<<block,threads,0,stream>>>( nshells, std::forward<Args>(args)... );
        break;
    }
  }

}


void eval_collocation_shell_to_task_gradient(
  uint32_t           nshells,
  uint32_t           L,
  uint32_t           pure,
  ShellToTaskDevice* shell_to_task_device,
  XCDeviceTask*      device_tasks,
  type_erased_queue  queue 
) {

  cudaStream_t stream = queue.queue_as<util::cuda_stream>() ;

  dispatch_shell_to_task_collocation_gradient( stream, L, pure, nshells, 
    shell_to_task_device, device_tasks );


}





} // namespace GauXC
