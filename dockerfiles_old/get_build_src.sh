#!/bin/bash

mkdir -p .build_src/
cd .build_src/
rm -rf *

wget https://github.com/artefactual/archivematica-storage-service/archive/v0.12.0.zip
unzip v0.12.0.zip
rm v0.12.0.zip
mv archivematica-storage-service-0.12.0 archivematica-storage-service

wget https://github.com/artefactual/archivematica-sampledata/archive/b7cfd5328501a64181b349eeb4e657cbf73e45ee.zip
unzip b7cfd5328501a64181b349eeb4e657cbf73e45ee.zip
rm b7cfd5328501a64181b349eeb4e657cbf73e45ee.zip
mv archivematica-sampledata-b7cfd5328501a64181b349eeb4e657cbf73e45ee archivematica-sampledata

wget https://github.com/wellcometrust/archivematica-fork/archive/080aecd6f4ccf87f87c129a073add0dd62f10fce.zip
unzip 080aecd6f4ccf87f87c129a073add0dd62f10fce.zip
rm 080aecd6f4ccf87f87c129a073add0dd62f10fce.zip
mv archivematica-fork-080aecd6f4ccf87f87c129a073add0dd62f10fce archivematica-fork

