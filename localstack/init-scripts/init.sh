#!/bin/bash
set -e
sleep 10
echo "Initialization started."

awslocal iam create-role --role-name apigw --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}'
echo "IAM 角色已創建"

# 創建 Lambda 函數
awslocal lambda create-function --function-name localstack_api --region ap-northeast-1 --runtime nodejs20.x --memory-size 128 --zip-file fileb:///tmp/my-function.zip --handler index.handler --role arn:aws:iam::000000000000:role/apigw


# 驗證 Lambda 函數是否存在
function check_lambda {
  for i in {1..10}; do
    if awslocal lambda get-function --function-name localstack_api --region ap-northeast-1; then
      echo "Lambda 函數存在"
      return 0
    else
      echo "等待 Lambda 函數創建... $i/10"
      sleep 5
    fi
  done
  echo "Lambda 函數創建失敗"
  return 1
}

if ! check_lambda; then
  exit 1
fi


# 創建 API Gateway v1 API
API_ID=$(awslocal apigateway create-rest-api --name "Demo" --region ap-northeast-1 | grep -E '"id"' | awk -F'"' '{print $4}')
echo "API_ID: $API_ID"

# 驗證 API 創建
awslocal apigateway get-rest-apis --region ap-northeast-1;

# 創建資源
PARENT_RESOURCE_ID=$(awslocal apigateway get-resources --rest-api-id $API_ID --region ap-northeast-1 | grep -E '"id"' | head -1 | awk -F'"' '{print $4}')
echo "PARENT_RESOURCE_ID $PARENT_RESOURCE_ID"

RESOURCE_ID=$(awslocal apigateway create-resource --rest-api-id $API_ID --parent-id $PARENT_RESOURCE_ID --path-part "demo" --region ap-northeast-1 | grep -E '"id"' | awk -F'"' '{print $4}')
echo "RESOURCE_ID $RESOURCE_ID"

COUPON_RESOURCE_ID=$(awslocal apigateway create-resource --rest-api-id $API_ID --parent-id $RESOURCE_ID --path-part "coupon" --region ap-northeast-1 | grep -E '"id"' | awk -F'"' '{print $4}')
echo "COUPON_RESOURCE_ID $COUPON_RESOURCE_ID"

DISTRIBUTE_RESOURCE_ID=$(awslocal apigateway create-resource --rest-api-id $API_ID --parent-id $COUPON_RESOURCE_ID --path-part "distribute" --region ap-northeast-1 | grep -E '"id"' | awk -F'"' '{print $4}')
echo "DISTRIBUTE_RESOURCE_ID = $DISTRIBUTE_RESOURCE_ID"

# 創建方法
awslocal apigateway put-method --rest-api-id $API_ID --resource-id $DISTRIBUTE_RESOURCE_ID --http-method POST --authorization-type "NONE" --region ap-northeast-1

# 創建整合
awslocal apigateway put-integration --rest-api-id $API_ID --resource-id $DISTRIBUTE_RESOURCE_ID --http-method POST --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:ap-northeast-1:lambda:path/2015-03-31/functions/arn:aws:lambda:ap-northeast-1:000000000000:function:localstack_api/invocations" --region ap-northeast-1 --passthrough-behavior WHEN_NO_MATCH

# 部署 API
DEPLOYMENT_ID=$(awslocal apigateway create-deployment --rest-api-id $API_ID --region ap-northeast-1 | grep -E '"id"' | awk -F'"' '{print $4}')
echo "Deployment ID: $DEPLOYMENT_ID"
curl -X POST http://localhost:4566/restapis/$API_ID/test/_user_request_/demo/coupon/distribute \
     -H "Content-Type: application/json" \
     -d '{"test": 123}'


echo "curl end"
# 添加 API Gateway stage
awslocal apigateway create-stage --rest-api-id $API_ID --stage-name "test" --deployment-id $DEPLOYMENT_ID --region ap-northeast-1

# 添加 Lambda 函數權限
aws lambda add-permission --function-name localstack_api --statement-id apigateway-test --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:ap-northeast-1:000000000000:$API_ID/test/POST/demo/coupon/distribute" --region ap-northeast-1 --endpoint-url=http://localhost:4566

echo "Lambda 函數權限已添加"
# 驗證 API 創建
awslocal apigateway get-rest-apis --region ap-northeast-1;

# 驗證 Lambda 創建
awslocal lambda list-functions --region ap-northeast-1;

# 執行 Lambda 函數
awslocal lambda invoke --function-name localstack_api --region ap-northeast-1 --payload '{}' response.json
echo "Lambda 函數已觸發"

awslocal sqs create-queue --queue-name demo_queue.fifo --attributes FifoQueue=true,ContentBasedDeduplication=false,DelaySeconds=0 --region ap-northeast-1

echo "Initialization complete."