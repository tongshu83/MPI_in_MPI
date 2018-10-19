
Load modules gcc/7.1.0, libpsm2/10.3-17, and cmake/3.9.4-3tixtqt
$ module unload intel-mkl/2017.3.196-v7uuj6z
$ module load gcc/7.1.0
$ module load libpsm2/10.3-17
$ module load cmake/3.9.4-3tixtqt

Download korvo
$ wget –q https://gtkorvo.github.io/korvo_bootstrap.pl

Set korvo
$ perl ./korvo_bootstrap.pl -i
Installed fresh ./korvo_build.pl
Installed fresh ./korvo_tag_db
Installed fresh ./korvo_arch
Installed fresh ./build_config
Specify version tag to use [stable] :
Specify install directory [\$HOME] : [Set install directory]
Configuring system for release "stable", install directory "[install directory]"

Edit korvo_build_config
$ vi korvo_build_config
...
% DISABLE_TESTING
...
korvogithub configure --disable-shared
korvogithub cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC -DTARGET_CNL=1 -DPKG_CONFIG_EXECUTABLE=IGNORE

$ perl ./korvo_build.pl

