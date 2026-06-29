ARG IMAGE_EXT

ARG REGISTRY=ghcr.io/epics-containers
ARG RUNTIME=${REGISTRY}/epics-base${IMAGE_EXT}-runtime:7.0.10ec1
ARG DEVELOPER=${REGISTRY}/ioc-areadetector${IMAGE_EXT}-developer:3.14ec2

##### build stage ##############################################################
FROM  ${DEVELOPER} AS developer

ENV SOURCE_FOLDER=/epics/generic-source
RUN ln -s ${SOURCE_FOLDER}/ioc ${IOC}

COPY requirements.txt requirements.txt
RUN uv pip install --upgrade -r requirements.txt

WORKDIR ${SOURCE_FOLDER}/ibek-support

COPY ibek-support/_ansible _ansible
ENV PATH=$PATH:${SOURCE_FOLDER}/ibek-support/_ansible

COPY ibek-support/ADSimDetector/ ADSimDetector
RUN ansible.sh ADSimDetector

COPY ioc ${SOURCE_FOLDER}/ioc
RUN ansible.sh ioc

##### runtime preparation stage ################################################
FROM developer AS runtime_prep

RUN ibek ioc extract-runtime-assets /assets /python

##### runtime stage ############################################################
FROM ${RUNTIME} AS runtime

# get runtime assets from the preparation stage
COPY --from=runtime_prep /assets /

# install runtime system dependencies, collected from install.sh scripts
RUN ibek support apt-install-runtime-packages

# launch the startup script with stdio-expose to allow console connections
CMD ["bash", "-c", "${IOC}/start.sh"]
