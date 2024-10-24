FROM ubuntu:rolling

ENV HOME_DIR=/root
ENV APP_DIR=/app
ENV TEMP_DIR=$APP_DIR/temp
WORKDIR $TEMP_DIR

RUN mkdir -p $TEMP_DIR

# Change repository mirrors
# Change repository mirrors
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://asia.archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com/ubuntu/|http://asia.security.ubuntu.com/ubuntu/|g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    ca-certificates \ 
    curl \
    git \
    gnupg \
    gnupg2 \
    software-properties-common \
    && rm -rf /var/lib/apt/listst/*

COPY ide/install_nodejs.sh $TEMP_DIR/
RUN ./install_nodejs.sh

COPY ide/install_vim_ppa.sh $TEMP_DIR/
RUN ./install_vim_ppa.sh

COPY ide/install_tmux.sh $TEMP_DIR/
RUN ./install_tmux.sh

COPY ide/install_python3.12.sh $TEMP_DIR/
RUN ./install_python3.12.sh

COPY ide/install_aws_cli.sh $TEMP_DIR/
RUN ./install_aws_cli.sh

COPY ide/install_others.sh $TEMP_DIR/
RUN ./install_others.sh


RUN mkdir -p $HOME_DIR/.dotfiles
COPY .. $HOME_DIR/.dotfiles

COPY ide/install_dotfiles.sh  $TEMP_DIR/
RUN ./install_dotfiles.sh



WORKDIR $HOME_DIR
