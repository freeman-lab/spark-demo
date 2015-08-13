# Docker image for Spark demo

FROM debian:jessie

MAINTAINER freemanlab <the.freeman.lab@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV CONDA_DIR /opt/conda

# Core installs
RUN apt-get update && \
    apt-get install -y git vim wget build-essential python-dev ca-certificates bzip2 libsm6 && \
    apt-get clean

# Install conda
RUN echo 'export PATH=$CONDA_DIR/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-3.9.1-Linux-x86_64.sh && \
    /bin/bash /Miniconda3-3.9.1-Linux-x86_64.sh -b -p $CONDA_DIR && \
    rm Miniconda3-3.9.1-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda install --yes conda==3.10.1

# Create a user
RUN useradd -m -s /bin/bash freemanlab
RUN chown -R freemanlab:freemanlab $CONDA_DIR

# Open port
EXPOSE 8888

# Env vars
USER freemanlab
ENV HOME /home/freemanlab
ENV SHELL /bin/bash
ENV USER freemanlab
ENV PATH $CONDA_DIR/bin:$PATH
WORKDIR $HOME

# Setup ipython
RUN conda install --yes ipython-notebook terminado && conda clean -yt
RUN ipython profile create

# Switch to root for permissions
USER root

# Java setup
RUN apt-get install -y default-jre

# Spark setup 
RUN wget http://d3kbcqa49mib13.cloudfront.net/spark-1.4.1-bin-hadoop1.tgz 
RUN tar -xzf spark-1.4.1-bin-hadoop1.tgz
ENV SPARK_HOME $HOME/spark-1.4.1-bin-hadoop1
ENV PATH $PATH:$SPARK_HOME/bin
RUN sed 's/log4j.rootCategory=INFO/log4j.rootCategory=ERROR/g' $SPARK_HOME/conf/log4j.properties.template > $SPARK_HOME/conf/log4j.properties
ENV _JAVA_OPTIONS "-Xms512m -Xmx4g" 

# Install useful Python packages
RUN apt-get install -y libxrender1 fonts-dejavu && apt-get clean
RUN conda create --yes -q -n python3.4-env python=3.4 nose numpy pandas scikit-learn scikit-image matplotlib scipy seaborn sympy cython patsy statsmodels cloudpickle numba bokeh pillow ipython jsonschema boto
ENV PATH $CONDA_DIR/bin:$PATH
RUN conda install --yes numpy pandas scikit-learn scikit-image matplotlib scipy seaborn sympy cython patsy statsmodels cloudpickle numba bokeh pillow && conda clean -yt
RUN /bin/bash -c "pip install mistune"

# Bolt setup
RUN apt-get install -y git python-pip ipython gcc
RUN git clone https://github.com/bolt-project/bolt
RUN /bin/bash -c "pip install -r bolt/requirements.txt"
ENV BOLT_ROOT $HOME/bolt
ENV PATH $PATH:$BOLT_ROOT/bin
ENV PYTHONPATH $PYTHONPATH:$BOLT_ROOT

# Add the notebooks directory
ADD notebooks $HOME/notebooks

# Add the data
ADD data $HOME/data

# Set up the kernelspec
RUN /opt/conda/envs/python3.4-env/bin/ipython kernelspec install-self

# Set permissions on the notebooks
RUN chown -R freemanlab:freemanlab $HOME/notebooks

# Switch back to non-root user
USER freemanlab

WORKDIR $HOME/notebooks

# Setup Spark + IPython env vars
ENV PYSPARK_PYTHON=/opt/conda/bin/python
ENV PYSPARK_DRIVER_PYTHON=/opt/conda/bin/python
ENV IPYTHON 1
ENV IPYTHON_OPTS "notebook --ip=0.0.0.0"

CMD /bin/bash -c pyspark --packages 