#!/bin/bash -l

set -eu

# Download Example-LAMMPS
if [ -d Example-LAMMPS ]
then
        rm -rf Example-LAMMPS
fi
git clone https://github.com/CODARcode/Example-LAMMPS.git

# Build Example-LAMMPS
cd Example-LAMMPS

# Compile LAMMPS
cd lammps/src
echo
echo "Build lammps ..."
make yes-kspace yes-manybody yes-molecule yes-user-adios_staging
make mpi -j8
make mpi -j8 mode=shlib

# Compile voro++-0.4.6
cd ../../voro++-0.4.6/src
echo
echo "build voro++-0.4.6 ..."
make -j8 CXX=mpicxx CFLAGS=-fPIC

# Compile adios_integration
cd ../../adios_integration
echo
echo "build adios_integration ..."
make -j8

# Compile swift-liblammps
# Edit swift-liblammps/build.sh
# Line 3: source $(turbine -C)
# Line 7: MPICC=$( which mpicc )
cd ../swift-liblammps
sed -i 's/^MPICC=$( which cc )$/MPICC=$( which mpicc )/' build.sh
echo
echo "build swift-liblammps ..."
./build.sh

# Compile swift-voro_adios
# Edit build.sh
# Line 3: source $(turbine -C)
# Line 7: MPICXX=$( which mpicxx )
cd ../swift-voro_adios
sed -i 's/^MPICXX=$( which CC )$/MPICXX=$( which mpicxx )/' build.sh
echo
echo "build swift-voro_adios ..."
./build.sh

# Compile swift-all
cd ../swift-all
echo
echo "build swift-all ..."
./build-16k.sh

# Execute
echo "Testing ..."
cd ..
APP=1
if [ $APP -eq 1 ]
then
	export PATH=$PWD/lammps/src:$PWD/adios_integration:$PATH
	cd swift-all
	mpiexec -n 8 ./lmp_mpi -i in.quench.short &
	mpiexec -n 4 ./voro_adios_omp_staging dump.bp adios_atom_voro.bp FLEXPATH

	if [ ! -d experiment ]
	then
		mkdir experiment
	fi
	cd experiment
	rm -f in.quench in.quench.short restart.liquid CuZr.fs
	ln -s ../in.quench in.quench
	ln -s ../in.quench.short in.quench.short
	ln -s ../restart.liquid restart.liquid
	ln -s ../CuZr.fs CuZr.fs
	cd ..
	cp -f ../../sbatch-bebop-lammps.sh sbatch-bebop-lammps.sh

else
	cd swift-all
	# Edit run.sh
	# Line 15: #module load mvapich2-gnu-psm/1.9
	# Line 34: #export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu
	# Line 35: PATH=/home/tshu/project/MPI_in_MPI/t7810/Example-LAMMPS/adios_integration:$PATH
	# Line 36: PATH=/home/tshu/project/MPI_in_MPI/t7810/Example-LAMMPS/lammps/src:$PATH
	sed -i 's/^module load mvapich2-gnu-psm\/1.9$/# module load mvapich2-gnu-psm\/1.9/' run.sh
	sed -i 's/^export LD_LIBRARY_PATH=\/home\/ltang\/Install\/lz4-1.8.1.2\/lib$/# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:\/usr\/lib\/x86_64-linux-gnu/' run.sh
	sed -i 's/^PATH=\/home\/ltang\/Example-LAMMPS\/adios_integration:\$PATH$/PATH='"$PWD"'\/adios_integration:$PATH/' run.sh
	# sed -i 's/^PATH=\/home\/ltang\/Example-LAMMPS\/adios_integration:\$PATH$/PATH=\/home\/tshu\/project\/bebop\/MPI_in_MPI\/bebop-psm2\/Example-LAMMPS\/swift-all\/adios_integration:$PATH/' run.sh
	sed -i 's/^PATH=\/home\/ltang\/Example-LAMMPS\/lammps\/src:\$PATH$/PATH='"$PWD"'\/lammps\/src:$PATH/' run.sh
	# sed -i 's/^PATH=\/home\/ltang\/Example-LAMMPS\/lammps\/src:\$PATH$/PATH=\/home\/tshu\/project\/bebop\/MPI_in_MPI\/bebop-psm2\/Example-LAMMPS\/swift-all\/lammps\/src:$PATH/' run.sh
	sed -i 's/in.quench/in.quench.short/' run.sh
	./run.sh
fi

cd ../..

