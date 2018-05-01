
usage () {
	echo ""
	echo "Usage: $0 -n <MasterStackName> -s <SimHostKeyPairName> -g <GatewayKeyPairName> [-S <SimHostRegion>] [-G <GatewayRegion>] [-b <BucketName>] [-p <AWSProfile>] "
	echo "  -n: Master stack name, should be short - 2-3 characters"
	echo "  -s: EC2 Key Pair name to leverage for simulated host access"
	echo "  -g: EC2 Key Pair name to leverage for storage gateway"
	echo "  -S: Sim host region, default is us-west-2"
	echo "  -G: Gateway region, default is us-east-2"
	echo "  -b: S3 bucket name to use for working directory for CloudFormation"
	echo "  -p: Default profile will be used unless you specify a different profile"
	echo ""
}

AWSPROFILE=
BUCKET='levvel-cloud-build-bucket'
MASTERSTACKNAME=
SIMHOSTKEYNAME=
GATEWAYKEYNAME=
SIMHOSTREGION='us-west-2'
GATEWAYREGION='us-east-2'

while getopts n:s:g:S:G:b:p: o
do
	case $o in
		n)
			MASTERSTACKNAME=$OPTARG
			;;
		b)
			BUCKET=$OPTARG
			;;
		s)
			SIMHOSTKEYNAME=$OPTARG
			;;
		g)
			GATEWAYKEYNAME=$OPTARG
			;;
		p)
			AWSPROFILE=$OPTARG
			;;
		S)
			SIMHOSTREGION=$OPTARG
			;;
		G)
			GATEWAYREGION=$OPTARG
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

if [ ! "$MASTERSTACKNAME" ] || [ ! "$SIMHOSTKEYNAME" ] #|| [ ! "$GATEWAYKEYNAME" ]
then
	usage
	exit -1
fi

aws ${AWSPROFILE:+--profile $AWSPROFILE}cloudformation package --template-file  master-stack.json --s3-bucket $BUCKET --output-template-file master-stack-packaged.json
aws ${AWSPROFILE:+--profile $AWSPROFILE}s3 mv ./master-stack-packaged.json  s3://${BUCKET}/
aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $SIMHOSTREGION cloudformation create-stack --stack-name ${MASTERSTACKNAME}-StorageGatewayMaster --capabilities CAPABILITY_NAMED_IAM --template-url https://s3.amazonaws.com/${BUCKET}/master-stack-packaged.json --parameters ParameterKey=MasterStackName,ParameterValue=$MASTERSTACKNAME ParameterKey=EC2Key,ParameterValue=$SIMHOSTKEYNAME ParameterKey=GatewayRegion,ParameterValue=$GATEWAYREGION
aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $SIMHOSTREGION cloudformation wait stack-create-complete --stack-name ${MASTERSTACKNAME}-StorageGatewayMaster


#aws ${AWSPROFILE:+--profile $AWSPROFILE}cloudformation package --template-file  simulated-host-stack.json --s3-bucket $BUCKET --output-template-file simulated-host-stack-packaged.json
#aws ${AWSPROFILE:+--profile $AWSPROFILE}s3 mv ./simulated-host-stack-packaged.json  s3://${BUCKET}/
#aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $SIMHOSTREGION cloudformation create-stack --stack-name ${MASTERSTACKNAME}-SimulatedOnPremises --capabilities CAPABILITY_NAMED_IAM --template-url https://s3.amazonaws.com/${BUCKET}/simulated-host-stack-packaged.json --parameters ParameterKey=MasterStackName,ParameterValue=$MASTERSTACKNAME ParameterKey=EC2Key,ParameterValue=$SIMHOSTKEYNAME
#aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $SIMHOSTREGION cloudformation wait stack-create-complete --stack-name ${MASTERSTACKNAME}-SimulatedOnPremises

#SECGROUP=`aws ec2 describe-security-groups --region us-west-1 --query 'SecurityGroups[?Tags[?Value==\`'"${MASTERSTACKNAME}"'-win1SecurityGroup\`]].GroupId' --output text`

#aws ${AWSPROFILE:+--profile $AWSPROFILE}cloudformation package --template-file  storage-gateway-stack.json --s3-bucket $BUCKET --output-template-file storage-gateway-stack-packaged.json
#aws ${AWSPROFILE:+--profile $AWSPROFILE}s3 mv ./storage-gateway-stack-packaged.json  s3://${BUCKET}/
#aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $GATEWAYREGION cloudformation create-stack --stack-name ${MASTERSTACKNAME}-GatewayStack --capabilities CAPABILITY_NAMED_IAM --template-url https://s3.amazonaws.com/${BUCKET}/storage-gateway-stack-packaged.json --parameters ParameterKey=MasterStackName,ParameterValue=$MASTERSTACKNAME ParameterKey=EC2Key,ParameterValue=$GATEWAYKEYNAME ParameterKey=SimHostSecurityGroup,ParameterValue=$SECGROUP  ParameterKey=SimHostInstance,ParameterValue=${MASTERSTACKNAME}-win1Instance
#aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $GATEWAYREGION cloudformation wait stack-create-complete --stack-name ${MASTERSTACKNAME}-GatewayStack

echo done
