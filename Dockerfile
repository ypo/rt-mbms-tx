FROM debian:bookworm as builder

WORKDIR /app

COPY ./cmake ./cmake
COPY ./conf_files ./conf_files
COPY ./debian ./debian
COPY ./lib ./lib
COPY ./srsenb ./srsenb
COPY ./srsepc ./srsepc
COPY ./srsue ./srsue
COPY ./test ./test
COPY ./cmake_uninstall.cmake.in ./cmake_uninstall.cmake.in
COPY ./CMakeLists.txt ./CMakeLists.txt
COPY ./CTestConfig.cmake ./CTestConfig.cmake
COPY ./CTestCustom.cmake.in ./CTestCustom.cmake.in
COPY ./run-clang-format-diff.sh ./run-clang-format-diff.sh
COPY ./build_trial.sh ./build_trial.sh
COPY ./.travis.yml ./.travis.yml
COPY ./.lgtm.yml ./.lgtm.yml

RUN apt-get update
RUN apt-get -y install build-essential cmake libfftw3-dev libmbedtls-dev libboost-program-options1.81-dev libconfig++-dev libsctp-dev

WORKDIR /app/build
RUN cmake ../ -DCMAKE_INSTALL_PREFIX=/usr/local
RUN cmake --build .
RUN cmake --install .

FROM debian:bookworm
WORKDIR /app

RUN apt-get update
RUN apt-get -y install libboost-program-options1.81.0 libmbedtls14 libsctp1 libfftw3-bin

COPY --from=builder /usr/local/bin/srsran_install_configs.sh /usr/local/bin/srsran_install_configs.sh
COPY --from=builder /usr/local/bin/srsmbms /usr/local/bin/srsmbms
COPY --from=builder /usr/local/bin/srsepc /usr/local/bin/srsepc
COPY --from=builder /usr/local/bin/srsepc_if_masq.sh /usr/local/bin/srsepc_if_masq.sh
COPY --from=builder /usr/local/share/srsran /usr/local/share/srsran

RUN ls -l /usr/local/share/srsran
RUN srsran_install_configs.sh user

RUN echo '#!/bin/sh' > /usr/local/bin/entrypoint.sh
RUN echo "srsmbms &" >> /usr/local/bin/entrypoint.sh
RUN echo "srsepc &" >> /usr/local/bin/entrypoint.sh
RUN echo 'wait' >> /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
