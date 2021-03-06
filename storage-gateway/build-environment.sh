
usage () {
	echo ""
	echo "Usage: $0 -n <MasterStackName> -s <SimHostKeyPairName>  [-p <AWSProfile>] "
	echo "  -n: Master stack name, should be short - 2-3 characters"
	echo "  -s: EC2 Key Pair name to leverage for simulated host access (us-west-2)"
	echo "  -r: EC2 Key Pair name to leverage for recovery host access (us-west-1), also toggles DR creation"
	echo "  -p: Default profile will be used unless you specify a different profile"
	echo ""
}

AWSPROFILE=
BUCKET='levvel-cloud-build-bucket'
MASTERSTACKNAME=
SIMHOST_KEYNAME=
SIMHOST_REGION='us-west-2'
GATEWAY_REGION='us-east-2'
CONFIG_DR=0
DRHOST_KEYNAME=
DRHOST_REGION='us-west-1'


while getopts n:r:s:p: o
do
	case $o in
		n)
			# bash generate random number between 0 and 99
			RAN=$(cat /dev/urandom | LC_CTYPE=C  tr -dc "[:alpha:]" | head -c 8)
			if [ "$RAN" == "" ]; then
			  RAN="abc"
			fi
			MASTERSTACKNAME=$OPTARG-$RAN
			;;
		s)
			SIMHOST_KEYNAME=$OPTARG
			;;
		r)
			DRHOST_KEYNAME=$OPTARG
			CONFIG_DR=1
			;;
		p)
			AWSPROFILE=$OPTARG
			;;
		\?)
			usage
			exit -1
			;;
		:)
			usage
			exit -1
			;;
		*)
			usage
			exit -1
			;;
	esac
done

if [ ! "$MASTERSTACKNAME" ] || [ ! "$SIMHOST_KEYNAME" ]
then
	usage
	exit -1
fi

aws ${AWSPROFILE:+--profile $AWSPROFILE}cloudformation package --template-file  gateway-master-stack.json --s3-bucket $BUCKET --output-template-file gateway-master-stack-packaged.json
aws ${AWSPROFILE:+--profile $AWSPROFILE}s3 mv ./gateway-master-stack-packaged.json  s3://${BUCKET}/
aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $SIMHOST_REGION cloudformation create-stack --stack-name ${MASTERSTACKNAME}-StorageGatewayMaster --capabilities CAPABILITY_NAMED_IAM --template-url https://s3.amazonaws.com/${BUCKET}/gateway-master-stack-packaged.json --parameters ParameterKey=MasterStackName,ParameterValue=$MASTERSTACKNAME ParameterKey=SimHostKey,ParameterValue=$SIMHOST_KEYNAME ParameterKey=GatewayRegion,ParameterValue=$GATEWAY_REGION
aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $SIMHOST_REGION cloudformation wait stack-create-complete --stack-name ${MASTERSTACKNAME}-StorageGatewayMaster

if [ "$CONFIG_DR" == 1 ]; then
	aws ${AWSPROFILE:+--profile $AWSPROFILE}cloudformation package --template-file  dr-master-stack.json --s3-bucket $BUCKET --output-template-file dr-master-stack-packaged.json
	aws ${AWSPROFILE:+--profile $AWSPROFILE}s3 mv ./dr-master-stack-packaged.json  s3://${BUCKET}/
	aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $DRHOST_REGION cloudformation create-stack --stack-name ${MASTERSTACKNAME}-DR-StorageGatewayMaster --capabilities CAPABILITY_NAMED_IAM --template-url https://s3.amazonaws.com/${BUCKET}/dr-master-stack-packaged.json --parameters ParameterKey=MasterStackName,ParameterValue=$MASTERSTACKNAME-DR ParameterKey=SimHostKey,ParameterValue=$DRHOST_KEYNAME ParameterKey=GatewayRegion,ParameterValue=$GATEWAY_REGION
	aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $DRHOST_REGION cloudformation wait stack-create-complete --stack-name ${MASTERSTACKNAME}-DR-StorageGatewayMaster
fi
echo done
