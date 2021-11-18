Command Line
============
Guideline notes on how to use COMSOL from the command line.

The main advantage of running COMSOL simulations from the command line in batch mode
is the ability to run multiple models at the same time, however, doing so on your
local machine might not be the best idea as the models would compete for resources
(RAM, in particular) and therefore might take longer to run simultaneously than they
would sequentially, or back to back. Fortunately, the Hawk supercomputer helps you 
overcome that problem giving you access to a High Performance Computational system 
with enough resources to solve several types of models even when run at the same time
(limited only by your licence restrictions).

The following notes aim to be a short tutorial about how to setup a COMSOL batch 
script to submit a simulation job on Hawk. We assume that you already have a working
model (mhp file) which you might want to run with different settings. 

For this we will again use the busbar model discussed in the "Cluster computing" 
section of these notes.

Requirements:

* A COMSOL model (mhp file)
* Knowledge of your floating network license address (e.g. 
  comsol_port@licence_server) 
* Hawk user account. Find more information about how to `create a user account`_.
* Hawk project account. Find more information about how to `create a project account`_.

Desirable:

* Familiarity with general `Linux Command Line`_ options. 
* Familiarity with the programming language `Bash`_.
* Familiarity with command line text editors.


Writing a job script
####################
Hawk is a shared system with many users in which resources are requested through a
scheduler software called *SLURM*. This is done via a `job script`, a text file with
the commands necessary to specify the resources needed to run a COMSOL simulation. 

We now explain step by step a simple job script to submit a COMSOL job on Hawk. Here 
you can find the :download:`full script <scripts/comsolexample_busbar.q>`.

.. code-block:: bash

   #!/bin/bash
   #SBATCH -J comsolbench_busbar # Job name
   #SBATCH -o %x.o.%J            # Job output file
   #SBATCH -e %x.e.%J            # Job error file
   #SBATCH --ntasks=4            # number of parallel processes (tasks)
   #SBATCH --ntasks-per-node=4   # number of tasks per node
   #SBATCH -p compute            # selected queue
   #SBATCH --time=00:30:00       # time limit
   #SBATCH --account=scwXXXX     # project account code

The first line ``#!/bin/bash`` tells Linux that this file contains code writted in
``Bash`` and should be executed by the ``Bash`` interpreter found in the provided 
path. In the ``Bash`` programming language lines beginning with a ``#`` symbol are 
treated as comments and ignored. However, this is a job script and is meant to be
read by the ``SLURM`` scheduler which scans the file looking for a specific 
combination of characters, ``#SBATCH``, and if found, treats the lines containing
them as directive specifying job requirements. There are several options at your
disposal to control the behaviour of your jobs, we provide a short summary in the
`SCW portal`_ and you can find a full list of options in the `SLURM website`_.

.. code-block:: bash

   set -eu

It is recommended to include the above option in your job script as it enables some
debugging options to capture some common errors.

.. code-block:: bash

   module purge
   module load comsol/all_licences/5.4
   module list

Next we load the required software, COMSOL 5.4 in this example. After this we define
a set of useful variables including the names of our model, input and output files,
the number of nodes and tasks requested for the job (using SLURM environment 
variables) and the address of your COMSOL's licence server. In this example we use
a licence owned by SCW for COMSOL 5.4 and restricted to a single concurrent user. Be
sure to change this line to point to your licence server if you wish to use specific
modules included with your licence. If in doubt, contact the licence owner or ARCCA
and we will do our best to point you in the right direction.

.. code-block:: bash

   export model=busbar
   export inputfile="${model}.mph"
   export outputfile="outfile.mph"
   export nn=$SLURM_NNODES
   export np=$SLURM_NTASKS
   export LMCOMSOL_LICENSE_FILE=1718@licence1.arcca.cf.ac.uk

We also set variables pointing to a Working Directory (``WDPATH``) where temporary 
files will be placed during job execution and an Output Directory (``ODPATH``) where
final files are to be copied. After this we make sure to create ``WDPATH`` and a 
subdirectory ``tmp`` required by COMSOL (notice that in this case ``ODPATH`` is the 
same location from where we submit the job, so there is no need to create it).

.. code-block:: bash

   WDPATH=/scratch/$USER/comsolbench_${model}/$SLURM_JOBID
   ODPATH=$SLURM_SUBMIT_DIR/LOGS_${model}
   mkdir -p $WDPATH
   mkdir $WDPATH/tmp

Next we copied the input simulation files and place ourselves in ``WDPATH``:

.. code-block:: bash

   cp $SLURM_SUBMIT_DIR/input/$inputfile $WDPATH
   cd $WDPATH

Finally we are ready to run comsol from the command line using its batch interface:

.. code-block:: bash

   comsol batch \
       -nn $nn \
       -np $np \
       -tmpdir $WDPATH/tmp \
       -inputfile $WDPATH/$inputfile \
       -outputfile $WDPATH/$outputfile \
       -batchlog $WDPATH/outputlog.${model}.${SLURM_JOBID}.log

In the above command the final ``\ `` in each line is a way to tell ``Bash`` that the
command continues in the next line and is used in this case to faciliate readability.
When COMSOL finishes (hopefully without error), we transfer any desired output files
to our output directory (``ODPATH``), in this case we are only interested in the 
logs. 

.. code-block:: bash

   cp $WDPATH/*.log $ODPATH

COMSOL has several settings to control its behaviour when used in batch mode. You
can find a more comprehensive list in COMSOL's documentation for `version 5.4`_ and for `version 5.5`_.

Running a COMSOL job
####################
With the above job script we can go ahead and submit our first COMSOL job. To do this
create a new folder in your home directory:

.. code-block:: bash

   ~$ mkdir comsol-test
   ~$ cd comsol-test
   ~/comsol-test$

Copy the job script, you can download it directly using the above link. You can 
download files directly from the internet to Hawk suing the command ``wget``:

.. code-block::

   ~/comsol-test$ wget comsol-link

Create a directory where to save COMSOL simulation files for the `busbar examples`_
for version 5.4:
.. code-block::

   ~/comsol-test$ mkdir input
   ~/comsol-test$ cd input

   ~/comsol-test/input$ wget https://uk.comsol.com/model/download/523001/busbar.mph
   --2021-10-04 18:08:52--  https://uk.comsol.com/model/download/523001/busbar.mph
   Resolving uk.comsol.com (uk.comsol.com)... 176.10.169.228
   Connecting to uk.comsol.com (uk.comsol.com)|176.10.169.228|:443... connected.
   HTTP request sent, awaiting response... 200 OK
   Length: 11165080 (11M) [application/vnd.comsol]
   Saving to: ‘busbar.mph’
   
   100%[================================================>] 11,165,080  1.09MB/s   in 9.8s
   
   2021-10-04 18:09:04 (1.09 MB/s) - ‘busbar.mph’ saved [11165080/11165080]

   ~/comsol-test/input$ wget https://uk.comsol.com/model/download/523031/busbar_box.mph
   --2021-10-04 18:13:45--  https://uk.comsol.com/model/download/523031/busbar_box.mph
   Resolving uk.comsol.com (uk.comsol.com)... 176.10.169.228
   Connecting to uk.comsol.com (uk.comsol.com)|176.10.169.228|:443... connected.
   HTTP request sent, awaiting response... 200 OK
   Length: 4427134 (4.2M) [application/vnd.comsol]
   Saving to: ‘busbar_box.mph’
   
   100%[================================================>] 4,427,134   1.70MB/s   in 2.5s
   
   2021-10-04 18:13:48 (1.70 MB/s) - ‘busbar_box.mph’ saved [4427134/4427134]


   ~/comsol-test/input$ wget https://uk.comsol.com/model/download/522971/busbar_geom.mph
   --2021-10-04 18:14:55--  https://uk.comsol.com/model/download/522971/busbar_geom.mph
   Resolving uk.comsol.com (uk.comsol.com)... 176.10.169.228
   Connecting to uk.comsol.com (uk.comsol.com)|176.10.169.228|:443... connected.
   HTTP request sent, awaiting response... 200 OK
   Length: 484013 (473K) [application/vnd.comsol]
   Saving to: ‘busbar_geom.mph’
   
   100%[================================================>] 484,013     2.28MB/s   in 0.2s
   
   2021-10-04 18:14:56 (2.28 MB/s) - ‘busbar_geom.mph’ saved [484013/484013]

Return to the parent directory ``comsol-test`` and edit the job script with the text
editor of your choice to include your project code:

.. code-block:: bash

   #SBATCH -A scwXXXX

Back in the command line submit the job using the SLURM command ``sbatch```:

.. code-block::

   ~/comsol-test$ sbatch comsolexample_busbar.q
   Submitted batch job 23835110

You can check the current status of your job with the SLURM command ``squeue``:

.. code-block::

   ~/comsol-test$ squeue
   23835110 c_compute comsolbe c.c10458  R	0:24	  1 ccs9025

.. _create a user account: https://portal.supercomputing.wales/index.php/getting-access/
.. _create a project account: https://portal.supercomputing.wales/index.php/getting-access/
.. _Linux Command Line: https://arcca.github.io/An-Introduction-to-Linux-with-Command-Line/
.. _Bash : https://arcca.github.io/An-Introduction-to-Linux-Shell-Scripting/
.. _SCW portal: https://portal.supercomputing.wales/index.php/index/slurm/migrating-jobs/
.. _SLURM website: https://slurm.schedmd.com/sbatch.html
.. _version 5.4: https://doc.comsol.com/5.4/doc/com.comsol.help.comsol/comsol_ref_running.29.30.html
.. _version 5.5: https://doc.comsol.com/5.5/doc/com.comsol.help.comsol/comsol_ref_running.29.30.html
.. _busbar examples: https://uk.comsol.com/model/electrical-heating-in-a-busbar-8484
