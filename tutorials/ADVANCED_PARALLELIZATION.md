# Run processes in parallel to speed up the simulation
Just using the maximum number of cores is not the most efficient way of parallelization.
Which increase in simulation time (if any) you can observe depends on many factors.
The easiest solutions is benchmarking.
For that purpose, FADE comes with a script (`fade/examples/parallel_bench.sh`) which can try different numbers of threads and report the best setting.

## Use all cores (not recommended)
You can set the number of threads that should be used with:
> fade <yourproject> parallel [CORPUS_THREADS] [PROCESSING_THREADS] [FEATURES_THREADS] [TRAINING_THREADS] [RECOGNITION_THREADS]

To simply use all available processing unit on your machine run the following on your project:
> fade <yourproject> parallel $(nproc) $(nproc) $(nproc) $(nproc) $(nproc)

## Determine good values for parallelization (recommended)
Set up a representative project '<yourproject>'.
A good way of improving performance is to run everything in a ramdisk, which you might consider.
Ubuntu Linux offers to use half of the system memory as a ramdisk (in `/dev/shm`).

Use the script as follows to start benchmarking with different numbers of threads:
> parallel_bench.sh <yourproject> 2 3 4 6 8 12 16
Select the number of threads appropiate for your computer, the example would be suitable for a machine with 16 logical cores.
You can check the number of available cores with:
> nproc

The script will run each stage of FADE with the requested numbers of threads and report the ones that resulted in the shortest simulation time.
This may take some time.

## Make the default values permanent
You can set the resulting values as your default settings in `fade/fade.d/parallel.cfg`

Our experience is that the optimal number can vary a lot, even on the same system, depending on the project and device that is used for storing the data.
If you plan to run a really large number of similar simulations optimizing the number of threads is recommended.

## Apply your default values to a new project
If you want to use the default values for parallelization in your project use:
> fade <yourproject> parallel




