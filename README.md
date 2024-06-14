# LocalStack Demo

這個專案是在展示如何在 local 開發的時候怎麼使用 `localstack` 去開發 `API GATEWAY` + `LAMBDA` 作為 API endpoint
然後轉發 request data 到 `SQS`，再由 worker 去 pull SQS data 下來


## 如何運行

1. `docker-compose up`
2. 在 localstack_demo log 中可以找到 `API_ID`


## API

假設我們有一個 API 端點可以用來分發優惠券：

請將 `${API_ID}` 替換為你的 API ID。
POST http://localhost:4566/restapis/${API_ID}/test/_user_request_/demo/coupon/distribute

這樣就可以在 local 端實現 API 應用