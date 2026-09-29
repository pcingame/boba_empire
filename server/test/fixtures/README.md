`test_ec_private.pem` — cặp khoá EC P-256 SINH RA để test, KHÔNG liên quan gì
tới khoá App Store Server API thật của app. An toàn để commit: chỉ dùng để ký
JWT/JWS giả trong `test/verifier_test.dart`.

Sinh lại nếu cần:
```
openssl ecparam -name prime256v1 -genkey -noout -out private.pem
openssl pkcs8 -topk8 -nocrypt -in private.pem -out test_ec_private.pem
```
