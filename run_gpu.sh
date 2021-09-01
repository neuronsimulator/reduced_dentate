#!/bin/bash

#SBATCH --account=proj16
# SBATCH --partition=prod
#SBATCH --time=01:00:00

#SBATCH --nodes=1
#SBATCH --constraint=volta
#SBATCH --gres=gpu:4
#SBATCH --ntasks-per-node=4

#SBATCH --cpus-per-task=2
#SBATCH --exclusive
#SBATCH --mem=0

# Stop on error
#set -e

# =============================================================================
# SIMULATION PARAMETERS TO EDIT
# =============================================================================

BASE_DIR=$(pwd)
INSTALL_DIR=$BASE_DIR/install
SOURCE_DIR=$BASE_DIR/sources

export HOC_LIBRARY_PATH=$BASE_DIR/templates
. $SOURCE_DIR/venv/bin/activate
PYTHONPATH_INIT=$PYTHONPATH

#Change this according to the desired runtime of the benchmark
export SIM_TIME=10

# =============================================================================
nvidia-cuda-mps-control -d # Start the daemon

echo "----------------- NEURON SIM (CPU) ----------------"
export PYTHONPATH=$INSTALL_DIR/nrn_cnrn_cpu_mod2c/lib/python:$PYTHONPATH_INIT
rm nrn_gpu.log nrn_gpu.spk
srun dplace $INSTALL_DIR/nrn_cnrn_cpu_mod2c/special/x86_64/special -c mytstop=$SIM_TIME run.hoc -mpi 2>&1 | tee nrn_gpu.log
# Sort the spikes
cat results/*spike* | sort -k 1n,1n -k 2n,2n > nrn_gpu.spk
rm -rf results

echo "----------------- CoreNEURON SIM (GPU_MOD2C) ----------------"
export PYTHONPATH=$INSTALL_DIR/nrn_cnrn_gpu_mod2c/lib/python:$PYTHONPATH_INIT
rm nrn_cnrn_gpu_mod2c.log nrn_cnrn_gpu_mod2c.spk
srun dplace $INSTALL_DIR/nrn_cnrn_gpu_mod2c/special/x86_64/special -c mytstop=$SIM_TIME -c coreneuron=1 -c gpu=1 run.hoc -mpi 2>&1 | tee nrn_cnrn_gpu_mod2c.log
# Sort the spikes
cat results/*spike* | sort -k 1n,1n -k 2n,2n > nrn_cnrn_gpu_mod2c.spk
rm -rf results

echo "----------------- CoreNEURON SIM (GPU_NMODL) ----------------"
export PYTHONPATH=$INSTALL_DIR/nrn_cnrn_gpu_nmodl/lib/python:$PYTHONPATH_INIT
rm nrn_cnrn_gpu_nmodl.log nrn_cnrn_gpu_nmodl.spk
srun dplace $INSTALL_DIR/nrn_cnrn_gpu_nmodl/special/x86_64/special -c mytstop=$SIM_TIME -c coreneuron=1 -c gpu=1 run.hoc -mpi 2>&1 | tee nrn_cnrn_gpu_nmodl.log
# Sort the spikes
cat results/*spike* | sort -k 1n,1n -k 2n,2n > nrn_cnrn_gpu_nmodl.spk
rm -rf results

echo quit | nvidia-cuda-mps-control
# =============================================================================

echo "---------------------------------------------"
echo "-------------- Compare Spikes ---------------"
echo "---------------------------------------------"

DIFF=$(diff nrn_gpu.spk nrn_cnrn_gpu_mod2c.spk)
if [ "$DIFF" != "" ] 
then
    echo "nrn_gpu.spk nrn_cnrn_gpu_mod2c.spk are not the same"
else
    echo "nrn_gpu.spk nrn_cnrn_gpu_mod2c.spk are the same"
fi

DIFF=$(diff nrn_gpu.spk nrn_cnrn_gpu_nmodl.spk)
if [ "$DIFF" != "" ] 
then
    echo "nrn_gpu.spk nrn_cnrn_gpu_nmodl.spk are not the same"
else
    echo "nrn_gpu.spk nrn_cnrn_gpu_nmodl.spk are the same"
fi

# =============================================================================

echo "---------------------------------------------"
echo "----------------- SIM STATS -----------------"
echo "---------------------------------------------"

echo "----------------- NEURON SIM STATS (CPU) ----------------"
grep "psolve" nrn_gpu.log
echo "----------------- CoreNEURON SIM (GPU_MOD2C) STATS ----------------"
grep "Solver Time : " nrn_cnrn_gpu_mod2c.log
echo "----------------- CoreNEURON SIM (GPU_NMODL) STATS ----------------"
grep "Solver Time : " nrn_cnrn_gpu_nmodl.log

echo "---------------------------------------------"
echo "---------------------------------------------"
