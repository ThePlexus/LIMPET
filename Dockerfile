FROM buildpack-deps:bookworm-curl AS build
LABEL maintainer="Simon Newton <simon.newton@gmail.com>"
RUN DEBIAN_FRONTEND=noninteractive apt update && \ 
	apt -y upgrade && \
	apt -y install curl git build-essential cmake libclang-dev
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
WORKDIR /build
RUN git clone https://github.com/cloudflare/networkquality-rs
WORKDIR /build/networkquality-rs
RUN cargo build --release

FROM telegraf:latest
RUN DEBIAN_FRONTEND=noninteractive apt update && \
	apt -y upgrade && apt install -y jq
COPY --from=build /build/networkquality-rs/target/release/mach /usr/local/bin
COPY telegraf.conf /etc/telegraf/
COPY mach-run /usr/local/bin/
ENTRYPOINT ["/entrypoint.sh"]
CMD ["telegraf"]
