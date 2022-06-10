ISIS Install Supplement
=======================
This contains a simple recipe for installing the [ISIS software](https://isis.astrogeology.usgs.gov/7.0.0/index.html).

ISIS is installed using anaconda, according to the [ISIS Installation Directions](https://github.com/USGS-Astrogeology/ISIS3#installation). 
However ISIS uses conda-forge packages, which are notoriously unstable. It is very
easy to install a broken environment, so we have a simple Makefile to create 
a consistent environment.

Note that there are two pieces of ISIS:

1. The software.
2. The isis data files, used by the software.

We have seperate rules for creating each of these, since you may well
update these independently.

Using the ISIS environment
--------------------------
ISIS uses [anaconda](https://www.anaconda.com/). We create a ISIS
environment. You can then either activate the environment, or
alternatively just use the full path to various programs to run this
directly without activating the environment.

You can also use the "< path >/bin/conda run < isis program >" to run
a program is the conda environment without directly activating the
environment. I'm not sure when that might be necessary, but running the program
fully in the the conda environment might be necessary in some case.

Install software
----------------
You can install the software by:

    make ISISROOT=<your isis root> ISISDATA=<your isisdata> install-isis
	
Thie ISISROOT value is the base directory that we install in. The ISISDATA
value is where the ISIS data files either are or you plan to download to.

This will download a copy of [Micromamba](https://mamba.readthedocs.io/en/latest/user_guide/micromamba.html) 
which is a small program that allows us to bootstrap installing a conda 
environment. We then use this program to download the ISIS conda environment.

Install ISIS Data
-----------------
You can install the ISIS data (without the large kernels) as described
in the [ISIS Documentation](https://github.com/USGS-Astrogeology/ISIS3#the-isis-data-area). There is a make rule to automate this:

    make ISISROOT=<your isis root> ISISDATA=<your isisdata> install-isis-data

Developer
---------
To simple install ISIS, you don't need to follow these step. But the ISIS
installation uses a frozen set of packages which you may want to update the
future. This can be done with the following steps:

1. activate whatever conda environment you already have on the system.
2. Make sure that you have [mamba](https://github.com/mamba-org/mamba) installed.
3. Run "make create-development-isis"
4. Activate the isis-test environment, making sure everything works. Do any
   tweaks needed to get a working environment.
5. Run "make update-spec-file"
6. Inspect the [isis-conda-spec-file.yml](./isis-conda-spec-file.yml) and make 
   sure that it makes sense.
7. If everything looks good, do a git commit to check in the new spec file.


