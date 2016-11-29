FROM fpco/stack-run

RUN apt-get update
RUN apt-get install -y git

RUN curl -sSL https://get.haskellstack.org/ | sh

ARG CACHEBUST=1

RUN git clone https://github.com/HugoDelval/distributed-complexity /distributed-complexity
RUN mv /distributed-complexity/* /
RUN stack setup
RUN stack build
