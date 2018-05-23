
usage () {
	echo ""
	echo "Usage: $0 -n <MasterStackName> -s <SimHostKeyPairName>  [-p <AWSProfile>] "
	echo "  -n: Master stack name, should be short - 2-3 characters"
	echo "  -s: EC2 Key Pair name to leverage for simulated host access"
	echo "  -p: Default profile will be used unless you specify a different profile"
	echo ""
}

AWSPROFILE=
BUCKET='levvel-cloud-build-bucket'
MASTERSTACKNAME=
SIMHOST_KEYNAME=
SIMHOST_REGION='us-west-2'
SIMHOST_GATEWAY_REGION='us-east-2'
DRHOST_KEYNAME=
DRHOST_REGION='us-west-1'
DRHOST_GATEWAY_REGION='us-east-1'

while getopts n:s:p: o
do
	case $o in
		n)
			# bash generate random number between 0 and 99
			NUMBER=$(cat /dev/urandom | LC_CTYPE=C  tr -dc "[:alpha:]" | head -c 8)
			if [ "$NUMBER" == "" ]; then
			  NUMBER=0
			fi
			MASTERSTACKNAME=$OPTARG-$NUMBER
			;;
		s)
			SIMHOST_KEYNAME=$OPTARG
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

aws ${AWSPROFILE:+--profile $AWSPROFILE}cloudformation package --template-file  simhost-master-stack.json --s3-bucket $BUCKET --output-template-file simhost-master-stack-packaged.json
aws ${AWSPROFILE:+--profile $AWSPROFILE}s3 mv ./simhost-master-stack-packaged.json  s3://${BUCKET}/
aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $SIMHOST_REGION cloudformation create-stack --stack-name ${MASTERSTACKNAME}-StorageGatewayMaster --capabilities CAPABILITY_NAMED_IAM --template-url https://s3.amazonaws.com/${BUCKET}/simhost-master-stack-packaged.json --parameters ParameterKey=MasterStackName,ParameterValue=$MASTERSTACKNAME ParameterKey=SimHostKey,ParameterValue=$SIMHOST_KEYNAME ParameterKey=GatewayRegion,ParameterValue=$SIMHOST_GATEWAY_REGION
aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $SIMHOST_REGION cloudformation wait stack-create-complete --stack-name ${MASTERSTACKNAME}-StorageGatewayMaster

echo done
