#
# This script will be located on S3 to be downloaded and run by an EC2
# app server instance to unzip and start a version of the Play app.
#

VERSION="$1"

if [ -z "$VERSION" ]; then
	if [ -f "current-app-version.txt" ]; then
		VERSION=$(cat current-app-version.txt)
	else
		echo "Version argument is missing and \"current-app-version.txt\" is not available."
		exit 1
	fi

	echo "Version argument is missing. Deploying latest version ${VERSION} as default."
fi

APPNAME="$app_zip_name"
ZIPFILE="$APPNAME-$VERSION.zip"
CURRENTDIR="$APPNAME-current"
TEMPDIR="$APPNAME-temp"


# Unzip archive to temporary directory

if [ ! -f "$ZIPFILE" ]; then
	echo "Archive $ZIPFILE not found!"
	exit 1
fi

if [ -d "$TEMPDIR" ]; then
	rm -r "$TEMPDIR"
fi

unzip "$ZIPFILE" -d "$TEMPDIR"


# Stop currently running app

if [ -d "$CURRENTDIR" ]; then
	if [ -f "$CURRENTDIR/RUNNING_PID" ]; then
		echo "App seems to be running. Killing process..."

		# Kill current app process
		kill $(cat $CURRENTDIR/RUNNING_PID)

		# Give app some time to shut down
		sleep 2s
	fi

	# Delete old deployment directory
	rm -r "$CURRENTDIR"
fi


# Move new app to "current" directory

mv "$TEMPDIR/$APPNAME-$VERSION" "$CURRENTDIR"
rm -r "$TEMPDIR"


# Load app credential variables

if [ ! -z "$credentials_file" ]; then
	source $credentials_file
fi


# Start new Play app with or without New Relic Java agent

if [ -f "/root/newrelic/newrelic.yml" ]; then
	nohup "$CURRENTDIR/bin/$APPNAME" \
		-mem 512 \
		-J-server \
		-Dhttp.port=80 \
		-Dconfig.resource=${app_production_conf} \
		-J-javaagent:/root/newrelic/newrelic.jar \
		&
else
	nohup "$CURRENTDIR/bin/$APPNAME" \
		-mem 512 \
		-J-server \
		-Dhttp.port=80 \
		-Dconfig.resource=${app_production_conf} \
		&
fi


# Submit deployment information to New Relic

if [ ! -z "${newrelic_app_id}" ]; then
	if [ ! -z "${newrelic_api_key}" ]; then
		curl -H "x-api-key:${newrelic_api_key}" -d "deployment[application_id]=${newrelic_app_id}" -d "deployment[description]=Version ${VERSION}" https://api.newrelic.com/deployments.xml
	fi
fi
