# Dockerfile - CentOS 7
# https://github.com/openresty/docker-openresty

FROM centos:7.4.1708

MAINTAINER Evan Wies <evan@neomantra.net>

# ARG http_proxy="http://x.x.x.x:x"
# ARG https_proxy="http://x.x.x.x:x"

# Docker Build Arguments
ARG RESTY_VERSION="1.11.2.5"
ARG RESTY_LUAROCKS_VERSION="2.3.0"
ARG RESTY_J="1"
ARG RESTY_CONFIG_OPTIONS="\
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    "
ARG RESTY_THIRD_MODULE="\
    FRiCKLE/ngx_cache_purge:2.3 \
    vozlt/nginx-module-vts:v0.1.15 \
    bymaximus/nginx-sticky-module-ng:master \
    "
ARG RESTY_CONFIG_OPTIONS_MORE=""

# 1) Install yum dependencies
# 2) Download OpenResty
# 3) Build OpenResty
# 4) Cleanup

RUN yum install -y \
        gcc \
        gcc-c++ \
        gd-devel \
        gettext \
        GeoIP-devel \
        libxslt-devel \
        make \
        perl \
        perl-ExtUtils-Embed \
        readline-devel \
        unzip \
        zlib-devel \
        openssl-devel \
        pcre-devel \
        git \
        net-tools \
        iproute \
    && cd /tmp \
    && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd /tmp/openresty-${RESTY_VERSION}/bundle \
    && for item in $RESTY_THIRD_MODULE; \
       do \
           start=`echo $item |awk '{print $1}'` \
           && if [ ${start} == "#" ];then continue; fi \
           && echo $item |awk -F":" '{print $1,$2}' | while read url ver; \
           do \
               git clone -b $ver https://github.com/${url}.git; \
           done \
           && mod=`echo $start | awk -F"/|:" '{print $2}'` \
           && RESTY_CONFIG_OPTIONS_MORE="${RESTY_CONFIG_OPTIONS_MORE} --add-module=bundle/${mod}"; \
       done \
    && cd /tmp/openresty-${RESTY_VERSION} \
    && ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && rm -rf \
        openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
    && curl -fSL http://luarocks.org/releases/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && cd luarocks-${RESTY_LUAROCKS_VERSION} \
    && ./configure \
        --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit \
        --lua-suffix=jit-2.1.0-beta3 \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make build \
    && make install \
    && cd /tmp \
    && rm -rf luarocks-${RESTY_LUAROCKS_VERSION} luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && git clone https://github.com/pintsized/lua-resty-http.git \
    && cd lua-resty-http; LUA_LIB_DIR=/usr/local/openresty/lualib/ make install \
    && cd /tmp \
    && rm -rf lua-resty-http \
    && yum clean all \
    && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin/:/usr/local/openresty/nginx/sbin/:/usr/local/openresty/bin/

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
