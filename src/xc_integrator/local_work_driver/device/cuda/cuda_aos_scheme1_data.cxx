#include "cuda_aos_scheme1.hpp"
#include "buffer_adaptor.hpp"
#include <gauxc/util/div_ceil.hpp>
#include "device/cuda/cuda_backend.hpp"

namespace GauXC {

template <typename Base>
CudaAoSScheme1<Base>::Data::~Data() noexcept = default;

template <typename Base>
CudaAoSScheme1<Base>::Data::Data(const DeviceRuntimeEnvironment& rt) :
  Base::Data( rt ) { }

template <typename Base>
size_t CudaAoSScheme1<Base>::Data::get_ldatoms() {
  constexpr auto weight_unroll = alg_constants::CudaAoSScheme1::weight_unroll;
  return util::div_ceil( this->global_dims.natoms, weight_unroll ) * weight_unroll;
}

template <typename Base>
size_t CudaAoSScheme1<Base>::Data::get_rab_align() {
  return sizeof(double2);
}


template <typename Base>
size_t CudaAoSScheme1<Base>::Data::get_submat_chunk_size(int32_t LDA, 
  int32_t dev_id) {

  constexpr auto max_submat_blocks = 
    alg_constants::CudaAoSScheme1::max_submat_blocks;

  int l2_cache_size;
  cudaDeviceGetAttribute(&l2_cache_size, cudaDevAttrL2CacheSize, dev_id);

  int l2_block_size = (int) sqrt(0.75 * ((double) l2_cache_size / 8));
  int min_block_size = LDA / max_submat_blocks;

  int block_size = std::max(l2_block_size, min_block_size);
  block_size = std::min(block_size, LDA);

  return block_size;

}

template struct CudaAoSScheme1<AoSScheme1Base>::Data;
#ifdef GAUXC_ENABLE_MAGMA
template struct CudaAoSScheme1<AoSScheme1MAGMABase>::Data;
#endif


}
