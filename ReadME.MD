
###  make cluster then run migrations
```bash 
make kind
./scripts/migrate_db.sh
```

### post and show Logs
```bash 
curl --request POST --data 'name=le%20guin&email=ursula_le_guin%40gmail.com'  127.0.0.1:8000/subscriptions --verbose
kc get pods -n zero2prod
kc logs <pod-name> -n zero2prod | jq
```