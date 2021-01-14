#include "sycl_pack_density.hpp"
#include <gauxc/exceptions/sycl_exception.hpp>

#include "sycl_device_properties.hpp"

namespace GauXC      {
namespace integrator {
namespace sycl       {

    using namespace GauXC::sycl;

    template <typename T>
    void submat_set_combined_kernel( size_t ntasks,
                                     XCTaskDevice<T>* device_tasks,
                                     T*               A,
                                     size_t           LDA ,
                                     cl::sycl::nd_item<3>& item_ct) {

        const size_t batch_id = item_ct.get_group(0);

        if( batch_id < ntasks ) {

            auto& task = device_tasks[ batch_id ];

            const auto  ncut              = task.ncut;
            const auto* submat_cut_device = task.submat_cut;
            const auto  LDAS              = task.nbe;
            auto* ASmall_device     = task.nbe_scr;

            //if( LDAS == LDAB ) return;

            const size_t tid_x = item_ct.get_global_id(2);
            const size_t tid_y = item_ct.get_global_id(1);

            int64_t i(0);
            for( size_t i_cut = 0; i_cut < ncut; ++i_cut ) {
                const int64_t i_cut_first  = submat_cut_device[ 3*i_cut     ];
                const int64_t delta_i      = submat_cut_device[ 3*i_cut + 1 ];;

                int64_t j(0);
                for( size_t j_cut = 0; j_cut < ncut; ++j_cut ) {
                    const int64_t j_cut_first  = submat_cut_device[ 3*j_cut ];
                    const int64_t delta_j      = submat_cut_device[ 3*j_cut + 1 ];

                    auto* ASmall_begin = ASmall_device + i           + j          *LDAS;
                    auto* ABig_begin   = A             + i_cut_first + j_cut_first*LDA ;

                    for( int64_t J = tid_y; J < delta_j; J += item_ct.get_local_range(1) )
                        for( int64_t I = tid_x; I < delta_i; I += item_ct.get_local_range(2) )
                            ASmall_begin[I + J*LDAS] = ABig_begin[I + J*LDA];

                    j += delta_j;
                }
                i += delta_i;
            }

        } // batch_id check
    }

    template <typename T>
    void task_pack_density_matrix(size_t ntasks, XCTaskDevice<T> *device_tasks,
                                  T *P_device, size_t LDP, cl::sycl::queue *queue) {

        cl::sycl::range<3> threads(1, max_warps_per_thread_block, warp_size), blocks(ntasks, 1, 1);

        GAUXC_SYCL_ERROR( queue->submit([&](cl::sycl::handler &cgh) {
                auto global_range = blocks * threads;

                cgh.parallel_for(cl::sycl::nd_range<3>(global_range, threads),
                                 [=](cl::sycl::nd_item<3> item_ct) {
                                     submat_set_combined_kernel(ntasks, device_tasks, P_device, LDP, item_ct);
                                 });
                }) );
    }

    template
    void task_pack_density_matrix( size_t      ntasks,
                                   XCTaskDevice<double>* device_tasks,
                                   double*               P_device,
                                   size_t                LDP,
                                   cl::sycl::queue*      queue );

}
}
}
