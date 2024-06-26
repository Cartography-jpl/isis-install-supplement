# Update these, or alternatively just specify them on the make line
ISISROOT=/opt/isis
ISISDATA=/opt/afids/data/isis_data

# DOCKER has some weird permission issues I don't understand. We may
# eventually sort this out, but for now just skip setting owner and group
# if we are in docker
ifdef IN_DOCKER
RSYNC_ARG=-azv --no-o --no-g
TAR_ARG=--no-same-owner
else
RSYNC_ARG=-azv
TAR_ARG=
endif

# Create the ISIS environment, using our frozen spec file
install-isis: micromamba isis-conda-spec-file-modify.yml
	-rm -r $(ISISROOT)
	./micromamba create -p $(ISISROOT) -y --file isis-conda-spec-file-modify.yml
	bash -c 'eval "$$($(ISISROOT)/bin/conda shell.bash hook)" && conda activate $(ISISROOT) && conda env config vars set ISISROOT=$(ISISROOT) ISISDATA=$(ISISDATA)'

isis-conda-spec-file-modify.yml: isis-conda-spec-file.yml
# We need to replace the local-channel line found in the spec file, since
# this is a hard coded path and isn't necessarily the same on this system
	( grep -B 1000 local-channel isis-conda-spec-file.yml | grep -v local-channel ) > isis-conda-spec-file-modify.yml
	echo "  - file://$$(pwd)/local-channel" >> isis-conda-spec-file-modify.yml
	( grep -A 1000 local-channel isis-conda-spec-file.yml | grep -v local-channel ) >> isis-conda-spec-file-modify.yml

# Old rsync command seems to be replaced with rclone.
install-isis-data:
	mkdir -p $(ISISDATA)
	cp rclone.conf $(ISISDATA)
	rclone --progress --config rclone.conf sync base_usgs: $(ISISDATA)/base
	rclone --progress --config rclone.conf --exclude='kernels/**' sync mex_usgs: $(ISISDATA)/mex
	rclone --progress --config rclone.conf --exclude='kernels/**' sync mro_usgs: $(ISISDATA)/mro
	rclone --progress --config rclone.conf --exclude='kernels/**' sync mgs_usgs: $(ISISDATA)/mgs
y	rclone --progress --config rclone.conf --exclude='kernels/**' sync lro_usgs: $(ISISDATA)/lro

temp:
	echo $(IN_DOCKER)
	echo $(RSYNC_ARG)

install-mex-data:
	@echo "Currently Mars Express HRSC doesn't work with the ISIS spice"
	@echo "web interface. So we download all the kernels needed."
	rclone --progress --config rclone.conf sync mex_usgs: $(ISISDATA)/mex

# We don't want to depend on there being an exisiting conda environment.
# So we download a minimum environment micromamba. This is just enough
# of a system to turn around and create an environment.
micromamba:
# Not all systems have wget, so we use curl here
	mkdir Temp
	curl -L -o Temp/micromamba.tar.bz2 https://micromamba.snakepit.net/api/micromamba/linux-64/latest
	cd Temp && tar $(TAR_ARG) -xf ./micromamba.tar.bz2
	mv Temp/bin/micromamba .
	rm -r Temp

# Directly create a conda enviroment. This may well be broken, but we
# can activate this, tweak, and fix things. This is done whenever we
# want to update the isis-conda-spec-file.yml file - so the is is more
# a development step rather than a installation step. This depends on
# having an existing conda environment that have activated before running
# this (e.g., conda activate base)

create-development-isis:
	-mamba env remove -n isis-test
	mamba create -n isis-test --override-channels -c ./local-channel -c usgs-astrogeology -c conda-forge -c defaults -y python=3.6 isis=6.0.0 ffmpeg==3.4.1=0 gsl==2.7 nsl-compatibility conda mamba
	source $(CONDA_PREFIX)/etc/profile.d/conda.sh && conda activate isis-test && conda env config vars set ISISROOT=$$CONDA_PREFIX ISISDATA=$(ISISDATA) && conda deactivate
	@echo "===================================================================="
	@echo "Make sure to test out the isis-test environment. Do whatever tweaks"
	@echo "are needed  to have a clean environment (possibly updating this"
	@echo "make rule). When it is working, you can go then run"
	@echo "make update-spec-file"
	@echo "===================================================================="

# The ISIS build depends on the library /lib64/libnsl.so.1 This is present on redhat
# 7, but not 8. We can create a simple compatibility package that makes sure this
# is available.
build-nsl-compatibility:
	mamba build --output-folder local-channel/ recipe/nsl-compatibility

update-spec-file:
	conda env export -n isis-test > isis-conda-spec-file.yml
