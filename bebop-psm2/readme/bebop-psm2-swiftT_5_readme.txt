
Load module tcl/8.6.6-x4wnbsg
$ module load tcl/8.6.6-x4wnbsg

Download the Java and Ant, and set environment variables
export JAVA_HOME=$HOME/software/jdk1.8.0_172
export PATH=$JAVA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$JAVA_HOME/lib

export ANT_HOME=$HOME/software/apache-ant-1.10.1
export PATH=$ANT_HOME/bin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ANT_HOME/lib

$ cd ~/project/bebop/MPI_in_MPI/bebop-psm2

Download swift-t
$ git clone https://github.com/swift-lang/swift-t.git
$ cd ~/project/bebop/MPI_in_MPI/bebop-psm2/swift-t
$ mkdir ~/project/bebop/MPI_in_MPI/bebop-psm2/swift-t/swift-t

Create initial setting
$ dev/build/init-settings.sh

Set swift-t install directory in swift-t-settings.sh
$ vi dev/build/swift-t-settings.sh
Line 9: export SWIFT_T_PREFIX=/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/swift-t/swift-t [swift-t install directory]

Compile and install swift-t
$ dev/build/build-swift-t.sh

Set environment variables
$ export SWIFT_T_HOME=$HOME/project/bebop/MPI_in_MPI/bebop-psm2/swift-t/swift-t [swift-t install directory]
$ export PATH=$SWIFT_T_HOME/turbine/bin:$SWIFT_T_HOME/stc/bin:$PATH

