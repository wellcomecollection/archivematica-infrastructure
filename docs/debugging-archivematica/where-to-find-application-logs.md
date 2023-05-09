# Where to find application logs

All the Archivematica microservices write their logs to our shared logging cluster.
You can use these links to jump to a pre-filtered search for Archivematica logs:

*   <a href="https://logging.wellcomecollection.org/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-7d,to:now))&_a=(columns:!(service_name,log),filters:!(('$state':(store:appState),meta:(alias:!n,disabled:!f,index:cb5ba262-ec15-46e3-a4c5-5668d65fe21f,key:ecs_cluster,negate:!f,params:(query:archivematica-prod),type:phrase),query:(match_phrase:(ecs_cluster:archivematica-prod)))),grid:(columns:(service_name:(width:169))),index:cb5ba262-ec15-46e3-a4c5-5668d65fe21f,interval:auto,query:(language:kuery,query:'not%20log:%22*ELB-HealthChecker*%22%20and%20not%20log:%22*SelfCheck:%20Database%20status%20OK*%22'),sort:!(!('@timestamp',desc)))">in prod</a>
*   <a href="https://logging.wellcomecollection.org/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-7d,to:now))&_a=(columns:!(service_name,log),filters:!(('$state':(store:appState),meta:(alias:!n,disabled:!f,index:cb5ba262-ec15-46e3-a4c5-5668d65fe21f,key:ecs_cluster,negate:!f,params:(query:archivematica-prod),type:phrase),query:(match_phrase:(ecs_cluster:archivematica-prod)))),grid:(columns:(service_name:(width:169))),index:cb5ba262-ec15-46e3-a4c5-5668d65fe21f,interval:auto,query:(language:kuery,query:'not%20log:%22*ELB-HealthChecker*%22%20and%20not%20log:%22*SelfCheck:%20Database%20status%20OK*%22'),sort:!(!('@timestamp',desc)))">in prod</a>

{% hint style="info" %}
There are a couple of extremely chatty logs which are filtered out by default, because they usually don't have any information relevant for debugging.
{% endhint %}
