FROM intel/oneapi-hpckit:2023.1.0-devel-ubuntu20.04

MAINTAINER Henry Wang <henryw7@stanford.edu>

RUN apt update
RUN apt install -y gcc g++ gfortran make vim git wget automake libtool

WORKDIR /installers

RUN wget https://boostorg.jfrog.io/artifactory/main/release/1.78.0/source/boost_1_78_0.tar.gz
RUN tar xvf boost_1_78_0.tar.gz
WORKDIR /installers/boost_1_78_0
RUN ./bootstrap.sh --prefix=/software/boost # --with-toolset=intel-linux
RUN ./b2 --without-python -q install
RUN sed 's/bsa::library_version_type/boost::serialization::library_version_type/g' -i /software/boost/include/boost/property_tree/ptree_serialization.hpp
RUN sed 's/result = m_o_sp->insert(std::make_pair(oid, s));/result = m_o_sp->insert(std::make_pair(oid, (SPT<const void>)s));/g' -i /software/boost/include/boost/serialization/shared_ptr_helper.hpp

ENV BOOST_ROOT="/software/boost"
ENV LD_LIBRARY_PATH="$BOOST_ROOT/lib:$LD_LIBRARY_PATH"
ENV LIBRARY_PATH="$BOOST_ROOT/lib:$LIBRARY_PATH"
ENV CPATH="$BOOST_ROOT/include:$CPATH"

WORKDIR /installers

RUN wget https://github.com/nubakery/bagel/archive/v1.1.1.tar.gz
RUN tar xvf v1.1.1.tar.gz
WORKDIR /installers/bagel-1.1.1
RUN libtoolize && aclocal && autoconf && autoheader && automake -a
RUN mkdir obj
WORKDIR /installers/bagel-1.1.1/obj
RUN ../configure MPICC=mpiicc MPICXX=mpiicpc --prefix="/software/bagel" CXXFLAGS="-DNDEBUG -O3" --enable-mkl --with-boost=$BOOST_ROOT --with-mpi=intel
RUN make -j 40
RUN make install

ENV PATH="/software/bagel/bin:$PATH"
ENV LD_LIBRARY_PATH="/software/bagel/lib:$LD_LIBRARY_PATH"
ENV LIBRARY_PATH="/software/bagel/lib:$LIBRARY_PATH"

WORKDIR /installers

# Otherwise BAGEL will Segmentation fault (core dumped)
ENV I_MPI_FABRICS="shm"
