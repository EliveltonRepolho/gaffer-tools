#!/bin/bash -e

ENV_FILE=$HOME/0-env.sh

source $ENV_FILE

homeDir=$HOME
echo "working in "$homeDir

cd $homeDir

#install tomcat
sudo curl -L -O $TOMCAT_URL

tomcatTarball=${TOMCAT_URL##*/}
tomcatDir=${tomcatTarball%%.tar.gz}
tar -xvf $tomcatTarball

CATALINA_HOME=$homeDir/$tomcatDir/
echo -e "CATALINA_HOME=${CATALINA_HOME}" >> $ENV_FILE

echo -e "\nexport CATALINA_HOME=${CATALINA_HOME}/" >> $homeDir/.bashrc

source $homeDir/.bashrc

#configure tomcat for the gaffer-rest service
schemaFile=$GAFFER_SCHEMA
restStorePropertiesFile=$GAFFER_REST_STOREPROPERTIES
graphconfig=$GAFFER_GRAPHCONFIG
echo "gaffer.schemas=${schemaFile}" >> $CATALINA_HOME/conf/catalina.properties
echo "gaffer.storeProperties=${restStorePropertiesFile}" >> $CATALINA_HOME/conf/catalina.properties
echo "gaffer.graph.config=${graphconfig}" >> $CATALINA_HOME/conf/catalina.properties

#ship the war files for the ui and rest
cp $UI_WAR $CATALINA_HOME/webapps/ui.war
cp $REST_WAR $CATALINA_HOME/webapps/rest.war

#change the port to 8085
echo "%s/8080/${REST_PORT}/g
w
q
" | ex $CATALINA_HOME/conf/server.xml

#start the webserver

cd $CATALINA_HOME/bin

./startup.sh

sleep 7

#set the ui layout configs
cp $UI_CONFIG $CATALINA_HOME/webapps/ui/config/config.json

cd $homeDir
