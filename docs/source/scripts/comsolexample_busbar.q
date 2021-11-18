#!/bin/bash
#SBATCH -J comsolbench_busbar # Job name
#SBATCH -o %x.o.%J            # Job output file
#SBATCH -e %x.e.%J            # Job error file
#SBATCH --ntasks=4            # number of parallel processes (tasks)
#SBATCH --ntasks-per-node=4   # number of tasks per node
#SBATCH -p compute            # selected queue
#SBATCH --time=00:30:00       # time limit
#SBATCH --account=scwXXXX     # project account code

# Enables debugging options
set -eu

# Load the software.
module purge
module load comsol/all_licences/5.4
module list

# Variables definition
export model=busbar
export inputfile="${model}.mph"
export outputfile="outfile.mph"
export nn=$SLURM_NNODES
export np=$SLURM_NTASKS
export LMCOMSOL_LICENSE_FILE=1718@licence1.arcca.cf.ac.uk

# Set directory to use
WDPATH=/scratch/$USER/comsolbench_${model}/$SLURM_JOBID
ODPATH=$SLURM_SUBMIT_DIR/LOGS_${model}

# Make directory
mkdir -p $WDPATH

# Create tmp directory somewhere other than on the node.
mkdir $WDPATH/tmp

# Copy input files.
cp $SLURM_SUBMIT_DIR/input/$inputfile $WDPATH

# Change to working directory
cd $WDPATH

# Run Comsol
comsol batch \
    -nn $nn \
    -np $np \
    -tmpdir $WDPATH/tmp \
    -inputfile $WDPATH/$inputfile \
    -outputfile $WDPATH/$outputfile \
    -batchlog $WDPATH/outputlog.${model}.${SLURM_JOBID}.log

# Make output directory
mkdir -p $ODPATH

# Copy output to $HOME
cp $WDPATH/*.log $ODPATH
