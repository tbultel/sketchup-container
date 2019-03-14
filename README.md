
Run SketchUp Make in container
==============================

Running SketchUp on Linux requires installation of Wine. That can
certainly be done as it is packaged for example for Fedora but
I prefer to keep my core workstation installation free of software
that I only use from time to time or which I only use for specific
purpose.

This repository helps me to run SketchUp Make 2017 from container
image, installed separately from by workstation packages.

The original version of this container was based on Fedora,
but latest wine version for Ubuntu give better results, and less 
installation steps

Build image
-----------

This repository does not distribute the actual SketchUp Make binary.
It will be downloaded at the time the container is built.

	xhost +
	docker build --network=host --build-arg=uid=$(id -u) -t sketchup .

Run the container
-----------------

The container image expects the directory with .skp files bind-mounted
to /data directory in the container. This is an example command to
run the container, mounting the user home directory:

	docker run \
		--read-only \
		--network=host \
		--tmpfs /tmp -v /tmp/.wine-$(id -u) \
		-e DISPLAY=$DISPLAY \
		--security-opt=label:type:spc_t --user=$(id -u):$(id -g) \
		-v /tmp/.X11-unix/X0:/tmp/.X11-unix/X0 \
		-v $HOME:/data --rm sketchup

Installing the STL extension
-----------------

The container comes with slightly modified STL extension to Sketchup.
Namely the STL export does not work with wine, and I had to cheat a little bit.

It is not installed automagically, but the extension package *sketchup-stl.rbz*
is present on the Desktop directory of the wine user, making it straightforward
to install in Sketchup through the Extension Manager
