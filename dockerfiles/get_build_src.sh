#!/bin/bash

cd .buildsrc/
rm -rf *

wget https://github.com/artefactual/archivematica-storage-service/archive/v0.12.0.zip
unzip v0.12.0.zip
rm v0.12.0.zip
mv archivematica-storage-service-0.12.0 archivematica-storage-service

wget https://github.com/artefactual/archivematica-sampledata/archive/b7cfd5328501a64181b349eeb4e657cbf73e45ee.zip
unzip b7cfd5328501a64181b349eeb4e657cbf73e45ee.zip
rm b7cfd5328501a64181b349eeb4e657cbf73e45ee.zip
mv archivematica-sampledata-b7cfd5328501a64181b349eeb4e657cbf73e45ee archivematica-sampledata

wget https://github.com/wellcometrust/archivematica-fork/archive/fb75e5c7092b986bb024c9cea336ec072a9a1fa7.zip
unzip fb75e5c7092b986bb024c9cea336ec072a9a1fa7.zip
rm fb75e5c7092b986bb024c9cea336ec072a9a1fa7.zip
mv archivematica-fork-fb75e5c7092b986bb024c9cea336ec072a9a1fa7 archivematica-fork

