#
# Dockerfile - Google Kubernetes UI
#
# - Build
# docker build --rm -t kubernetes:ui .
#
# - Run
# docker run -d --name="kubernetes-ui" -h "kubernetes-ui" kubernetes:ui
#
# Use the base images
FROM ubuntu:17.04
MAINTAINER Yongbok Kim <ruo91@yongbok.net>

# The last update and install package for docker
RUN apt-get update && apt-get install -y git-core curl build-essential

# Variable
ENV SRC_DIR /opt
WORKDIR $SRC_DIR

# Build version
ENV BUILD_VER 20170702

# GO Language
ENV GO_ARCH linux-amd64
ENV GOROOT $SRC_DIR/go
ENV GOPATH $SRC_DIR/gopath
ENV PATH $PATH:$GOROOT/bin:$GOPATH/bin
RUN curl -XGET https://github.com/golang/go/tags | grep tag-name > /tmp/golang_tag \
 && sed -e 's/<[^>]*>//g' /tmp/golang_tag > /tmp/golang_ver \
 && GO_VER=`sed -e 's/      go/go/g' /tmp/golang_ver | head -n 1` && rm -f /tmp/golang_* \
 && curl -LO "https://storage.googleapis.com/golang/$GO_VER.$GO_ARCH.tar.gz" \
 && tar -C $SRC_DIR -xzf go*.tar.gz && rm -rf go*.tar.gz \
 && echo '' >> /etc/profile \
 && echo '# Golang' >> /etc/profile \
 && echo "export GOROOT=$GOROOT" >> /etc/profile \
 && echo "export GOPATH=$GOPATH" >> /etc/profile \
 && echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >> /etc/profile \
 && echo '' >> /etc/profile

# Kube UI
RUN git clone https://github.com/kubernetes/kube-ui
#ADD production.json $SRC_DIR/kube-ui/master/shared/config/production.json
RUN cd kube-ui \
 && go get github.com/tools/godep \
 && go get -u github.com/jteeuwen/go-bindata/... \
 && go get k8s.io/kube-ui/data && make kube-ui \
 && mv kube-ui /bin/kube-ui \
 && chmod a+x /bin/kube-ui \
 && cd .. && rm -rf kube-ui

# Removing unnecessary packages and files
RUN apt-get autoremove -y git-core curl build-essential && apt-get clean all

# Port
EXPOSE 8080

# Daemon
CMD ["/bin/kube-ui", "-port", "8080"]
