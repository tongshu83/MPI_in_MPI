
Download the Java, and set environment variables
export JAVA_HOME=$HOME/software/jdk1.8.0_172
export PATH=$JAVA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$JAVA_HOME/lib

$ cd ~/project/MPI_in_MPI/t7810

Download swift-t
$ git clone https://github.com/swift-lang/swift-t.git
$ cd ~/project/MPI_in_MPI/t7810/swift-t
$ mkdir ~/project/MPI_in_MPI/t7810/swift-t/swift-t

Create initial setting
$ dev/build/init-settings.sh

Set swift-t install directory in swift-t-settings.sh
$ vi dev/build/swift-t-settings.sh
Line 9: export SWIFT_T_PREFIX=$HOME/project/MPI_in_MPI/t7810/swift-t/swift-t [swift-t install directory]

Compile and install swift-t
$ dev/build/build-swift-t.sh

Set environment variables
$ export SWIFT_T_HOME=[swift-t install directory]
$ export PATH=$SWIFT_T_HOME/turbine/bin:$SWIFT_T_HOME/stc/bin:$PATH

