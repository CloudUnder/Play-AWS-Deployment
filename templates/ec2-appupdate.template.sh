#
# This script will be located on S3 to be downloaded and run by an EC2
# app server instance to download the latest version of the Play app
# and start it.
#

cd /root/


# Download web application deployment script

aws s3 cp "${s3_deployment_url}/ec2-deploy" .
if [ ! -f "ec2-deploy" ]; then
	echo "Deployment script \"ec2-deploy\" not found!"
	exit 1
fi

chmod 0700 ec2-deploy


# Download current app version number

aws s3 cp "${s3_deployment_url}/current-app-version.txt" .
if [ ! -f "current-app-version.txt" ]; then
	echo "current-app-version.txt not found!"
	exit 1
fi
VERSION=$(cat current-app-version.txt)


# Download latest app credentials

if [ ! -z "$credentials_file" ]; then
	aws s3 cp "${s3_deployment_url}/${credentials_file}" .
	if [ ! -f "${credentials_file}" ]; then
		echo "Credentials file \"${credentials_file}\" not found!"
		exit 1
	fi
fi


# Download web application

APPZIP="${app_zip_name}-${VERSION}.zip"
aws s3 cp "${s3_deployment_url}/${APPZIP}" .
if [ ! -f "${APPZIP}" ]; then
	echo "${APPZIP} not found!"
	exit 1
fi


# Deploy web application

./ec2-deploy ${VERSION}
