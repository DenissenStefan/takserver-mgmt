#!/bin/bash
# Created by: Stefan
# Created on: 9-12-2022

# Files are defined here:
XML_FILE="/opt/tak/CoreConfig.xml"

# Variables below are automatically pulled from the config:
IP=$(<"/opt/tak/certs/ConnectionName.txt")
HostName=$HOSTNAME

if [ $HostName == "localhost.localhost" ]; then
	echo "Hostname not set, please set hostname followed by a reboot of the server."
	exit 1
fi

#This is to remove the trailing space after the variable
IP=`echo $IP | sed -e 's/^[[:space:]]*//'`

# This outputs the CoreConfig node:
CaPass=$(xmllint --xpath "//*[local-name()='Configuration']/*[local-name()='security']/*[local-name()='tls']/@keystorePass" $XML_FILE)
ClientPass=$(xmllint --xpath "//*[local-name()='Configuration']/*[local-name()='security']/*[local-name()='tls']/@truststorePass" $XML_FILE)
intermediateCert=$(xmllint --xpath "//*[local-name()='Configuration']/*[local-name()='certificateSigning']/*[local-name()='TAKServerCAConfig']/@keystoreFile" $XML_FILE)
ServerCert=$(xmllint --xpath "//*[local-name()='Configuration']/*[local-name()='security']/*[local-name()='tls']/@keystoreFile" $XML_FILE)

# This extracts the entry from the CoreConfig node:
CaPass=${CaPass#*'"'}; CaPass=${CaPass%'"'*}
ClientPass=${ClientPass#*'"'}; ClientPass=${ClientPass%'"'*}
ServerCert=${ServerCert#*'"'}; ServerCert=${ServerCert%'"'*}
intermediateCert=${intermediateCert#*'"'}; intermediateCert=${intermediateCert%'"'*}

if

	[ -z "$intermediateCert" ]

then

	TrustStoreCert=$ServerCert
	TrustStoreCert=$(echo $TrustStoreCert | cut -c13- | rev | cut -c5- | rev)
else

	TrustStoreCert=$intermediateCert
	TrustStoreCert=$(echo $TrustStoreCert | cut -c13- | rev | cut -c13- | rev)
	TrustStoreCert="truststore-$TrustStoreCert"
fi

######################################################################

# Create a directory for storage of the user certificates & data-packages
mkdir -p "/opt/takdata/user-certificates"
mkdir -p "/opt/takdata/data-packages"


declare -i COUNTER=0 
{ 
    while test $COUNTER -le 100 
        do 
            echo $COUNTER 

		    # server.pref

		    echo "Creating server.pref file"

            COUNTER=COUNTER+10 

		    echo "<?xml version='1.0' encoding='ASCII' standalone='yes'?>" > /opt/tak/certs/server.pref
		    echo "<preferences>" >> /opt/tak/certs/server.pref
		    echo "  <preference version=\"1\" name=\"cot_streams\">" >> /opt/tak/certs/server.pref
		    echo "    <entry key=\"count\" class=\"class java.lang.Integer\">1</entry>" >> /opt/tak/certs/server.pref
		    echo "    <entry key=\"description0\" class=\"class java.lang.String\">$HostName</entry>" >> /opt/tak/certs/server.pref
		    echo "    <entry key=\"enabled0\" class=\"class java.lang.Boolean\">true</entry>" >> /opt/tak/certs/server.pref
		    echo "    <entry key=\"connectString0\" class=\"class java.lang.String\">$IP:8089:ssl</entry>" >> /opt/tak/certs/server.pref
		    echo "  </preference>" >> /opt/tak/certs/server.pref
		    echo "  <preference version=\"1\" name=\"com.atakmap.app_preferences\">" >> /opt/tak/certs/server.pref
		    echo "    <entry key=\"displayServerConnectionWidget\" class=\"class java.lang.Boolean\">true</entry>" >> /opt/tak/certs/server.pref
		    echo "    <entry key=\"caLocation\" class=\"class java.lang.String\">$TrustStoreCert.p12</entry>" >> /opt/tak/certs/server.pref
		    echo "    <entry key=\"caPassword\" class=\"class java.lang.String\">$CaPass</entry>" >> /opt/tak/certs/server.pref
            echo "    <entry key=\"enrollForCertificateWithTrust0\" class=\"class java.lang.Boolean\">true</entry>" >> /opt/tak/certs/server.pref
            echo "    <entry key=\"useAuth0\" class=\"class java.lang.Boolean\">false</entry>" >> /opt/tak/certs/server.pref
		    echo "  </preference>" >> /opt/tak/certs/server.pref
		    echo "</preferences>" >> /opt/tak/certs/server.pref

            COUNTER=COUNTER+20 

		    # manifest.xml

	    	echo "Creating manifest.xml file for $Username"

            COUNTER=COUNTER+10 

		    echo "<MissionPackageManifest version=\"2\">" > /opt/tak/certs/manifest.xml
		    echo "  <Configuration>" >> /opt/tak/certs/manifest.xml
		    echo "    <Parameter name=\"uid\" value=\"af6f9606-4e37-4d85-b14e-3d0a99705a9d\"/>" >> /opt/tak/certs/manifest.xml
		    echo "    <Parameter name=\"name\" value=\"$HostName\"/>" >> /opt/tak/certs/manifest.xml
		    echo "    <Parameter name=\"onReceiveDelete\" value=\"false\"/>" >> /opt/tak/certs/manifest.xml
		    echo "  </Configuration>" >> /opt/tak/certs/manifest.xml
		    echo "  <Contents>" >> /opt/tak/certs/manifest.xml
		    echo "    <Content zipEntry=\"server.pref\" ignore=\"false\" />" >> /opt/tak/certs/manifest.xml
		    echo "    <Content zipEntry=\"$TrustStoreCert.p12\" ignore=\"false\" />" >> /opt/tak/certs/manifest.xml
		    echo "  </Contents>" >> /opt/tak/certs/manifest.xml
		    echo "</MissionPackageManifest>" >> /opt/tak/certs/manifest.xml

            COUNTER=COUNTER+20 

		    echo "zipping files for Certificate Enrollment Datapackage"

            COUNTER=COUNTER+10 

		    # Zip files into a datapackage
	    	zip -j "/opt/takdata/data-packages/dp-CertEnrollment-$HostName.zip" "/opt/tak/certs/manifest.xml" "/opt/tak/certs/server.pref" "/opt/tak/certs/files/$TrustStoreCert.p12"

            COUNTER=COUNTER+10 

		    wait

		    echo "-------------------------------------------------------------"
		    echo "Created certificate data package for Certificate Enrollment @ $HostName as takdata/data-packages/dp-CertEnrollment-$HostName.zip"

            COUNTER=COUNTER+10 
            sleep 1 
    done 
    } |  dialog --backtitle "$BACKTITLE" --title "$TITLE - Certificate Enrollment" --gauge  "Creating datapackage for certificate enrollment"  10 50 0 

# Cleanup of server.pref & manifest.xml
rm "/opt/tak/certs/manifest.xml"
rm "/opt/tak/certs/server.pref"

clear

./ManagementConsole.sh