

This model of a dentate granule cell was taken from the following
paper and modified by Ivan Raikov:

Pedro Mateos-Aparicio, Ricardo Murphy and Johan F. Storm (2014). 
Complementary functions of SK and Kv7/M potassium channels in 
excitability control and synaptic integration in rat hippocampal 
dentate granule cells. Journal of Physiology 592, 669-693.

It is based on the model of Aradi & Holmes (1999; Journal of 
Computational Neuroscience 6, 215-235) which uses an idealized 
morphology (DGC_Morphology.hoc). The model was used to help 
understand the contribution of M and SK channels to the medium 
afterhyperpolarization (mAHP) following one or seven spikes, as 
well as the contribution of M channels to the slow 
afterhyperpolarization (sAHP). 

### Running this model with NEURON and CoreNEURON

```bash
# NOTE: you need different version of NEURON build for CPU and GPU i.e.
# -DCORENRN_ENABLE_GPU=ON and -DCORENRN_ENABLE_GPU=OFF
# NEURON is built as:

module load unstable nvhpc cuda cmake python hpe-mpi
cmake .. .. -DCMAKE_INSTALL_PREFIX=$HOME/bbp/nrn/build_gpu/install \
  -DCORENRN_ENABLE_GPU=ON -DNRN_ENABLE_CORENEURON=ON \
  -DNRN_ENABLE_INTERVIEWS=OFF -DNRN_ENABLE_RX3D=OFF
make -j8
make install

# lets use GPU enabled NEURON version
export PATH=$HOME/bbp/nrn/build_gpu/install/bin:$PATH
export PYTHONPATH=$HOME/bbp/nrn/build_gpu/install/lib/python/:$PYTHONPATH

# GPU partition of BB5
salloc --partition=prod --account=proj16 --nodes=1 --time=8:00:00 --exclusive --constraint=volta

# cd to reduced_dentat model dir
nrnivmodl -coreneuron mechanisms

export HOC_LIBRARY_PATH=`pwd`/templates

# run neuron on CPU
rm -rf results out.nrn.spk
srun -n 4 ./x86_64/special -c mytstop=10 run.hoc  -mpi
cat results/*spike* | sort -k 1n,1n -k 2n,2n > out.nrn.spk

# run with coreneuron gpu
rm -rf results out.cnrn.spk
#srun -n 4 ./x86_64/special -c mytstop=10 -c coreneuron=1 -c gpu=0 run.hoc  -mpi
srun -n 4 ./x86_64/special -c mytstop=10 -c coreneuron=1 -c gpu=1 run.hoc  -mpi
cat results/*spike* | sort -k 1n,1n -k 2n,2n > out.cnrn.spk
```

And then diff `out.nrn.spk` and `out.cnrn.spk`. They should be same unless there is possibility of floating point discrepencies.
