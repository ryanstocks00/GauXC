/**
 * GauXC Copyright (c) 2020-2023, The Regents of the University of California,
 * through Lawrence Berkeley National Laboratory (subject to receipt of
 * any required approvals from the U.S. Dept. of Energy). All rights reserved.
 *
 * See LICENSE.txt for details
 */
#pragma once
#include <gauxc/xc_integrator/replicated/replicated_xc_host_integrator.hpp>
#include "xc_host_data.hpp"

namespace GauXC {
namespace detail {

template <typename ValueType>
class ReferenceReplicatedXCHostIntegrator : 
  public ReplicatedXCHostIntegrator<ValueType> {

  using base_type  = ReplicatedXCHostIntegrator<ValueType>;

public:

  static constexpr bool is_device = false;
  using value_type = typename base_type::value_type;
  using basis_type = typename base_type::basis_type;
  using task_container = std::vector<XCTask>;
  using task_iterator  = typename task_container::iterator;

protected:

  void integrate_den_( int64_t m, int64_t n, const value_type* P,
                      int64_t ldp, value_type* N_EL ) override;

  void eval_exc_vxc_( int64_t m, int64_t n, const value_type* P,
                      int64_t ldp, value_type* VXC, int64_t ldvxc,
                      value_type* EXC ) override;

  void eval_exc_vxc_( int64_t m, int64_t n, const value_type* Pscalar,
                      int64_t ldpscalar,
                      const value_type* Pz,
                      int64_t ldpz,
                      value_type* VXCscalar, int64_t ldvxcscalar,
                      value_type* VXCz, int64_t ldvxcz,
                      value_type* EXC ) override;

  void eval_exc_grad_( int64_t m, int64_t n, const value_type* P,
                       int64_t ldp, value_type* EXC_GRAD ) override;

  void eval_exx_( int64_t m, int64_t n, const value_type* P,
                  int64_t ldp, value_type* K, int64_t ldk,
                  const IntegratorSettingsEXX& settings ) override;

  void integrate_den_local_work_( const value_type* P, int64_t ldp, 
                                   value_type *N_EL );

  void exc_vxc_local_work_( const basis_type& basis, const value_type* P, 
                            int64_t ldp, value_type* VXC, int64_t ldvxc, 
                            value_type* EXC, value_type *N_EL,
                            task_iterator task_begin, task_iterator task_end );

  void exc_vxc_local_work_( const value_type* Pscalar, int64_t ldpscalar,
                            const value_type* Pz, int64_t ldpz,
                            value_type* VXCscalar, int64_t ldvxcscalar,
                            value_type* VXCz, int64_t ldvxcz, value_type* EXC, value_type *N_EL );
                            
  void exc_grad_local_work_( const value_type* P, int64_t ldp, value_type* EXC_GRAD );
  void exx_local_work_( const value_type* P, int64_t ldp, value_type* K, int64_t ldk,
    const IntegratorSettingsEXX& settings );

public:

  template <typename... Args>
  ReferenceReplicatedXCHostIntegrator( Args&&... args ) :
    base_type( std::forward<Args>(args)... ) { }

  virtual ~ReferenceReplicatedXCHostIntegrator() noexcept;


  template <typename... Args>
  void exc_vxc_local_work(Args&&... args) {
    exc_vxc_local_work_( std::forward<Args>(args)... );
  }
};

extern template class ReferenceReplicatedXCHostIntegrator<double>;

}
}
