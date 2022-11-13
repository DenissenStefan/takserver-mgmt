#!/bin/bash
# Created by: Stefan
# Created on: 5-10-2022
# Note: this only works when the server certificate name is the same as the hostname

# Files are defined here:
XML_FILE="/opt/tak/CoreConfig.xml"

# Variables below are automatically pulled from the config:
IP=`hostname -I`
HostName=$HOSTNAME
#This is to remove the trailing space after the variable
IP=`echo $IP | sed -e 's/^[[:space:]]*//'`

# This needs to be pulled from coreconfig.xml in the future, needs to be an if/else statement. If intermediate CA then certificate X, else certificate X from coreconfig.xml
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
else
	TrustStoreCert=$intermediateCert
fi

# This removes the file extension and the path from the string:
TrustStoreCert=$(echo $TrustStoreCert | cut -c13- | rev | cut -c5- | rev)

######################################################################

# This needs to come from a CSV in the future:
UserGroup="ExampleGroup"

File="users.txt"
Users=$(cat $File)

# Create a directory for storage of the user certificates
mkdir -p "/opt/takdata/user-certificates"
# Create a directory for storage of the user data-packages
mkdir -p "/opt/takdata/data-packages"

for User in $Users
do
	# User Certificates
	echo "Creating certificate for $User"
	./makeCert.sh client $User
	
	# Without this wait functions certificate generation won't finish and the certificates won't be usable.
	wait

	# User account
	echo "Creating user account for $User"
	java -jar /opt/tak/utils/UserManager.jar certmod -g $UserGroup /opt/tak/certs/files/$User.pem

	# The same as the wait function before, this makes sure the process will finish before the script continues.
	wait
	
	# server.pref

	echo "Creating server.pref file for $User"

	echo "<?xml version='1.0' encoding='ASCII' standalone='yes'?>" > server.pref
	echo "<preferences>" >> server.pref
	echo "  <preference version=\"1\" name=\"cot_streams\">" >> server.pref
	echo "    <entry key=\"count\" class=\"class java.lang.Integer\">1</entry>" >> server.pref
	echo "    <entry key=\"description0\" class=\"class java.lang.String\">$HostName</entry>" >> server.pref
	echo "    <entry key=\"enabled0\" class=\"class java.lang.Boolean\">true</entry>" >> server.pref
	echo "    <entry key=\"connectString0\" class=\"class java.lang.String\">$IP:8089:ssl</entry>" >> server.pref
	echo "  </preference>" >> server.pref
	echo "  <preference version=\"1\" name=\"com.atakmap.app_preferences\">" >> server.pref
	echo "    <entry key=\"displayServerConnectionWidget\" class=\"class java.lang.Boolean\">true</entry>" >> server.pref
	echo "    <entry key=\"caLocation\" class=\"class java.lang.String\">$TrustStoreCert.p12</entry>" >> server.pref
	echo "    <entry key=\"caPassword\" class=\"class java.lang.String\">$CaPass</entry>" >> server.pref
	echo "    <entry key=\"clientPassword\" class=\"class java.lang.String\">$ClientPass</entry>" >> server.pref
	echo "    <entry key=\"certificateLocation\" class=\"class java.lang.String\">$User.p12</entry>" >> server.pref
	echo "  </preference>" >> server.pref
	echo "</preferences>" >> server.pref


	# manifest.xml

	echo "Creating manifest.xml file for $User"

	echo "<MissionPackageManifest version=\"2\">" > manifest.xml
	echo "  <Configuration>" >> manifest.xml
	echo "    <Parameter name=\"uid\" value=\"af6f9606-4e37-4d85-b14e-3d0a99705a9d\"/>" >> manifest.xml
	echo "    <Parameter name=\"name\" value=\"$HostName\"/>" >> manifest.xml
	echo "    <Parameter name=\"onReceiveDelete\" value=\"false\"/>" >> manifest.xml
	echo "  </Configuration>" >> manifest.xml
	echo "  <Contents>" >> manifest.xml
	echo "    <Content zipEntry=\"server.pref\" ignore=\"false\" />" >> manifest.xml
	echo "    <Content zipEntry=\"$TrustStoreCert.p12\" ignore=\"false\" />" >> manifest.xml
	echo "    <Content zipEntry=\"$User.p12\" ignore=\"false\" />" >> manifest.xml
	echo "  </Contents>" >> manifest.xml
	echo "</MissionPackageManifest>" >> manifest.xml

	echo "zipping files for $User"

	# Zip files into a datapackage
	zip -j "/opt/takdata/data-packages/dp-$User-$HostName.zip" "/opt/tak/certs/manifest.xml" "/opt/tak/certs/server.pref" "/opt/tak/certs/files/$TrustStoreCert.p12" "/opt/tak/certs/files/$User.p12"

	wait

	# Create a subdirectory for the user certificates
	mkdir -p "/opt/takdata/user-certificates/$User"

	# This will move all files for the user to the user-certificates folder created above
	find . -name "$User*.*" -exec mv '{}' "/opt/takdata/user-certificates/$User/" \;

	echo "-------------------------------------------------------------"
	echo "Created certificate data package for $User @ $HostName as takdata/data-packages/dp-$User-$HostName.zip"


done

# Cleanup of server.pref & manifest.xml
rm "/opt/tak/certs/manifest.xml"
rm "/opt/tak/certs/server.pref"


