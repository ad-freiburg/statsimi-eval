# statsimi evaluation

Evaluation of statsimi, a tool for similarity classification of public transit stations.

## Run without Docker

Given statsimi is installed on your system and the ``statsimi`` command available, the Makefile can be used directly.

### Targets

Use these targets either as ``make <target>`` if statsimi is already installed, or as ``sudo docker run <container> <target>`` when using a Docker container (see below).

 * ``help`` Display help
 * ``eval`` Run evaluation for each dataset
 * ``freiburg_eval`` Run evaluation on the Freiburg dataset
 * ``london_eval`` Run evaluation on the London dataset
 * ``dach_eval`` Run evaluation on the combined dataset of Germany, Austria and Switzerland

Evaluation results and the geodata will be written into a folder ``/data``.

## Run with Docker

The evaluation can also be run inside a Docker container. The container can be used as an executable with the same targets as for the Makefile:

Build container:

    $ sudo docker build -t statsimi-eval .

Run evaluation:

    $ sudo docker run statsimi-eval eval

Geodata and evaluation results will be printed to ``/root/data`` inside the container.
To easily retrieve them, mount ``/root/data`` to a local folder:

    $ sudo docker run -v /local/folder/:/root/data statsimi-eval eval

# Normalization

A normalization file for German datasets can be found in this repository (``normalization.rules``).
Prepend the targets with ``NORM_FILE=normalization.rules`` to use it, e.g.:

    $ sudo docker run -v /local/folder/:/root/data statsimi-eval NORM_FILE=normalization.rules eval
