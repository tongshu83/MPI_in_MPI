
# This loads all modules for all builds for consistency

# Load modules gcc/7.1.0, libpsm2/10.3-17, and cmake/3.12.2-4zllpyo
# module spider cmake/3.12.2-4zllpyo
echo
echo Loading modules...
echo

module unload intel-mkl/2017.3.196-v7uuj6z
# module load gcc/7.3.0-xyzezhj
module load intel/17.0.4-74uvhji
module load intel-mpi/2017.3-dfphq6k
# module load libpsm2/10.3-17
module load cmake/3.12.2-4zllpyo
module load jdk/8u141-b15-mopj6qr
module load tcl/8.6.6-x4wnbsg

module load readline/7.0-3qkdfwk
module load bzip2/1.0.6-hcvyuh5
module load xz/5.2.4-okshegf
module load curl/7.60.0-6ldg322
# module load pcre/8.42-qe2sqsa
# module load zlib/1.2.11-6632jqd
module load libxml2/2.9.8-eqqbnqd

module load octave/4.2.1

echo
echo Modules OK
echo

