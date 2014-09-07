#
# This script will be located in the local path of the app and can be used
# to create and upload a new version of the app which should then be ready
# to deploy to app servers.
#

VERSION=$(grep "version :=" build.sbt | awk -F\" '{print $(NF-1)}')
ZIPFILE="target/universal/$app_zip_name-$VERSION.zip"

while true; do
	read -p "Do you wish to package app as version $VERSION? " yn
	case $yn in
		[Yy]* ) break;;
		[Nn]* ) exit;;
	* ) echo "Please answer y or n.";;
	esac
done

# --- PLEASE DOUBLE CHECK AND EDIT THIS SECTION TO YOUR NEEDS ------------------

echo "Double-check the build commands before you use this script!"
exit 1

# rm -r public/*
# grunt dist
# rm -r public/dev/
activator clean dist

# ------------------------------------------------------------------------------

if [ ! -f "$ZIPFILE" ]; then
	echo "Distribution package $ZIPFILE not found!"
	exit 1
fi

while true; do
	read -p "Do you want to upload the package to S3? " yn
	case $yn in
		[Yy]* ) break;;
		[Nn]* ) exit;;
	* ) echo "Please answer y or n.";;
	esac
done

echo "Starting upload..."
aws --profile $local_aws_profile s3 cp $ZIPFILE $s3_deployment_url && \
	echo "$VERSION" > current-app-version.txt && \
	aws --profile $local_aws_profile s3 cp current-app-version.txt $s3_deployment_url && \
	echo "If uploads were successful you can now deploy the new version."
rm current-app-version.txt
