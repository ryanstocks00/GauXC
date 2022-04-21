#include "ut_common.hpp"
#include <gauxc/load_balancer.hpp>

using namespace GauXC;


void gen_ref_lb_data( std::vector<XCTask>& tasks, size_t pv ) {

  int world_size;
  int world_rank;
#ifdef GAUXC_ENABLE_MPI
  MPI_Comm_size( MPI_COMM_WORLD, &world_size );
  MPI_Comm_rank( MPI_COMM_WORLD, &world_rank );
#else
  world_size = 1;
  world_rank = 0;
#endif

  std::string ref_file = GAUXC_REF_DATA_PATH "/benzene_cc-pvdz_ufg_tasks_" + std::to_string(world_size) + "mpi_rank" + std::to_string(world_rank) + 
    "_pv" + std::to_string(pv) + ".bin";

  // Points / Weights not stored in reference data to 
  // save space
  for( auto& t : tasks ) {
    t.points.clear();
    t.weights.clear();
  }

  std::ofstream of( ref_file, std::ios::binary );
  cereal::BinaryOutputArchive ar(of);
  ar( tasks );

}

void check_lb_data( const std::vector<XCTask>& tasks, size_t pv ) {

  int world_size;
  int world_rank;
#ifdef GAUXC_ENABLE_MPI
  MPI_Comm_size( MPI_COMM_WORLD, &world_size );
  MPI_Comm_rank( MPI_COMM_WORLD, &world_rank );
#else
  world_size = 1;
  world_rank = 0;
#endif

  std::string ref_file = GAUXC_REF_DATA_PATH "/benzene_cc-pvdz_ufg_tasks_" + std::to_string(world_size) + "mpi_rank" + std::to_string(world_rank) + 
    "_pv" + std::to_string(pv) + ".bin";

  std::vector<XCTask> ref_tasks;
  {
    std::ifstream ifile( ref_file, std::ios::binary );
    cereal::BinaryInputArchive ar(ifile);
    ar( ref_tasks );
  }

  REQUIRE( tasks.size() == ref_tasks.size() );

  size_t ntasks = tasks.size();
  for( size_t i = 0; i < ntasks; ++i ) {

    const auto& t  = tasks[i]; 
    const auto& rt = ref_tasks[i];
    CHECK( t.iParent == rt.iParent );
    CHECK( t.dist_nearest == Approx(rt.dist_nearest) );
    CHECK( t.npts == rt.npts );
    CHECK( t.points.size() == rt.npts );
    CHECK( t.weights.size() == rt.npts );
    CHECK( t.bfn_screening.shell_list == rt.bfn_screening.shell_list );
    CHECK( t.bfn_screening.nbe == rt.bfn_screening.nbe );

    /* 
    // Points / Weights not stored in reference data to 
    // save space
    REQUIRE( t.points.size() == rt.points.size() );
    size_t npts = t.points.size();
    for( size_t j = 0; j < npts; ++j ) {
      CHECK( t.points[j][0] == Approx(rt.points[j][0]) );
      CHECK( t.points[j][1] == Approx(rt.points[j][1]) );
      CHECK( t.points[j][2] == Approx(rt.points[j][2]) );
      CHECK( t.weights[j] == Approx(rt.weights[j]) );
    }
    */

  }

}


//#define GAUXC_GEN_TESTS
TEST_CASE( "DefaultLoadBalancer", "[load_balancer]" ) {

#ifdef GAUXC_ENABLE_MPI
  MPI_Comm comm = MPI_COMM_WORLD;
#endif

  Molecule mol           = make_benzene();
  BasisSet<double> basis = make_ccpvdz( mol, SphericalType(true) );

  for( auto& sh : basis ) 
    sh.set_shell_tolerance( std::numeric_limits<double>::epsilon() );

  MolGrid mg(AtomicGridSizeDefault::UltraFineGrid, mol);

  auto meta = std::make_shared<MolMeta>( mol );

#ifdef GAUXC_GEN_TESTS

  size_t pv = 1;
  SECTION("PV = 1") {}
  SECTION("PV = 32") { pv = 32; }

  LoadBalancerFactory lb_factory( ExecutionSpace::Host, "Default" );
  auto lb = lb_factory.get_instance( GAUXC_MPI_CODE(comm,) mol, mg, basis, pv);
  auto& tasks = lb.get_tasks();
  gen_ref_lb_data(tasks, pv);

#else

  SECTION("Default Host") {

    size_t pv = 1;
    SECTION("PV = 1") {}
    SECTION("PV = 32") { pv = 32; }

    LoadBalancerFactory lb_factory( ExecutionSpace::Host, "Default" );
    auto lb = lb_factory.get_instance( GAUXC_MPI_CODE(comm,) mol, mg, basis, pv);
    auto& tasks = lb.get_tasks();
    check_lb_data( tasks, pv );

    for( auto&& task : tasks ) {
      CHECK(!( task.points.size()  % pv ) );
      CHECK(!( task.weights.size() % pv ) );
    }

  }

#ifdef GAUXC_ENABLE_CUDA
  SECTION("Default Device") {

    size_t pv = 1;
    SECTION("PV = 1") {}
    SECTION("PV = 32") { pv = 32; }

    LoadBalancerFactory lb_factory( ExecutionSpace::Device, "Default" );
    auto lb = lb_factory.get_instance( GAUXC_MPI_CODE(comm,) mol, mg, basis, pv);
    auto& tasks = lb.get_tasks();
    check_lb_data( tasks, pv );


    for( auto&& task : tasks ) {
      REQUIRE(!( task.points.size()  % pv ) );
      REQUIRE(!( task.weights.size() % pv ) );
    }
    
    // Make sure Host/Device tasks are identical
    LoadBalancerFactory host_lb_factory( ExecutionSpace::Host, "Default" );
    auto host_lb = host_lb_factory.get_instance( GAUXC_MPI_CODE(comm,) mol, mg, basis, pv);
    auto& host_tasks = host_lb.get_tasks();

    for( auto i = 0; i < host_tasks.size(); ++i ) {
      const auto& points   = tasks[i].points;
      const auto& h_points = host_tasks[i].points;
      const auto& weights   = tasks[i].weights;
      const auto& h_weights = host_tasks[i].weights;

      REQUIRE( points.size() == h_points.size() );
      REQUIRE( weights.size() == h_weights.size() );
      for( auto j = 0; j < points.size(); ++j ) {
        CHECK( points[j][0] == Approx( h_points[j][0] ) );
        CHECK( points[j][1] == Approx( h_points[j][1] ) );
        CHECK( points[j][2] == Approx( h_points[j][2] ) );

        CHECK( weights[j] == Approx( h_weights[j] ) );
      }

      CHECK( tasks[i].bfn_screening.shell_list == host_tasks[i].bfn_screening.shell_list );
    }
  }
#endif

#endif


}
