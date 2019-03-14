FROM artefactual/fits-ngserver:0.8.4

# Install Java 8, which is what the compiled JARs for the Facebook ng-server
# have been compiled with.  If you don't install OpenJDK 8, you get this error
# when you try to start the server:
#
#     Exception in thread "main" java.lang.UnsupportedClassVersionError:
#     com/facebook/nailgun/NGServer : Unsupported major.minor version 52.0
#
USER root
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | \
  debconf-set-selections
RUN echo debconf shared/accepted-oracle-license-v1-1 seen true | \
  debconf-set-selections
RUN set -ex \
  && add-apt-repository --yes ppa:webupd8team/java \
  && apt-get update \
  && apt-get install --yes --force-yes --no-install-recommends openjdk-8-jre \
  && rm -rf /var/lib/apt/lists/*

# Then install the new ng-server from Facebook
RUN mkdir -p /usr/share/maven-repo/com/facebook/nailgun-server
RUN curl 'http://central.maven.org/maven2/com/facebook/nailgun-server/1.0.0/nailgun-server-1.0.0.jar' \
  -o /usr/share/maven-repo/com/facebook/nailgun-server/nailgun-server-1.0.0.jar

USER fits
COPY fits-ngserver.sh /usr/bin/fits-ngserver.sh

ENTRYPOINT ["/usr/bin/fits-ngserver.sh", "/usr/share/maven-repo/com/facebook/nailgun-server/nailgun-server-1.0.0.jar"]
