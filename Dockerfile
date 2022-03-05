FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu18.04

ARG PYTHON_VERSION=3.9.6

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
        build-essential \
        libbz2-dev \
        libdb-dev \
        libffi-dev \
        libgdbm-dev \
        liblzma-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        tk-dev \
        unzip \
        uuid-dev \
        wget \
        zlib1g-dev \
    && apt autoremove && apt autoclean

# Pythonインストール
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz &&\
    tar -xf Python-${PYTHON_VERSION}.tgz &&\
    cd Python-${PYTHON_VERSION} &&\
        ./configure &&\
        make &&\
        make install &&\
    cd ../ && rm -rf ./Python-${PYTHON_VERSION}.tgz ./Python-${PYTHON_VERSION}/ &&\
    ln -s /usr/local/bin/python3.9 /usr/local/bin/python

# pipインストール
WORKDIR /opt/app/
COPY ./requirements.txt ./requirements.txt
RUN /usr/local/bin/python -m pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt -f https://download.pytorch.org/whl/torch_stable.html

# Jupyter Notebook設定
ENV CONFIG /root/.jupyter/jupyter_notebook_config.py
ENV CONFIG_IPYTHON /root/.ipython/profile_default/ipython_config.py
RUN jupyter notebook --generate-config --allow-root && \
    ipython profile create
RUN echo "c.NotebookApp.ip = '0.0.0.0'" >>${CONFIG} && \
    echo "c.NotebookApp.port = 8888" >>${CONFIG} && \
    echo "c.NotebookApp.open_browser = False" >>${CONFIG} && \
    echo "c.NotebookApp.iopub_data_rate_limit=10000000000" >>${CONFIG} && \
    echo "c.MultiKernelManager.default_kernel_name = 'python3'" >>${CONFIG} && \
    echo "c.InteractiveShellApp.exec_lines = ['%matplotlib inline']" >>${CONFIG_IPYTHON}

WORKDIR /opt/app/
RUN chmod -R a+w .

RUN echo "alias ll='ls -lahF'" >> ~/.bashrc

CMD ["jupyter","notebook", "--allow-root"]
