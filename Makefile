IMAGE_TAG := 1.0.0
MODULE_NAME := zero2prod
CLUSTER_NAME := zero2prod

DB_USER:=postgres
DB_PASSWORD:=password
DB_NAME:=newsletter
DB_PORT:=5432
DB_HOST:=localhost

test:
	echo $(DATABASE_URL)
pg:
	SKIP_DOCKER=true && ./scripts/init_db.sh

decrypt:
	@for FILE in $$(find -E . -regex '.*\.enc\.(json|yaml|env)' | egrep '\.enc\.(json|yaml|env)') ;  do \
	  echo "decrypting $$FILE ..." ; \
	  DECRYPTED_FILE=$$(echo $$FILE | sed -e 's/.enc//') ; \
	  sops -d $$FILE > $$DECRYPTED_FILE ; \
	done ;

kind: decrypt
	./kind/create-cluster.sh $(CLUSTER_NAME)
	chmod +x ./kind/config.sh && ./kind/config.sh $(CLUSTER_NAME)
	echo DATABASE_URL=postgres://$(DB_USER):$(DB_PASSWORD)@localhost:$(DB_PORT)/$(DB_NAME) 
	export IMAGE_TAG=$(IMAGE_TAG) && skaffold --module $(MODULE_NAME) dev -v debug 

encrypt:
	@for FILE in $$(find -E . -regex '.+\.secret[^/]*\.(json|yaml|env)' | egrep -v '\.enc\.(json|yaml|env)') ;  do \
	  echo "encrypting $$FILE ..." ; \
	  ENCRYPTED_FILE=$$(echo $$FILE | sed -e 's/.(json|yaml|env)/.enc.(json|yaml|env)/' ) ; \
	  echo "encrypted file name $$ENCRYPTED_FILE .." ;\
	  sops --encrypt --gcp-kms projects/tribespark/locations/us-central1/keyRings/builds/cryptoKeys/code-secrets $$FILE > $$ENCRYPTED_FILE ; \
	done ;

production: decrypt
	kubectl config use-context gke_tribespark_us-central1-a_allspark-cluster
	export IMAGE_TAG=$(IMAGE_TAG) && skaffold --module $(MODULE_NAME) -p production run
	
clean-secrets:
	@for FILE in $$(find -E . -regex '.+\.secret[^/]*\.(json|yaml|env)' | egrep -v 'enc') ;  do \
		rm $$FILE ; \
	done

clean: clean-secrets
	kind delete cluster --name=$(CLUSTER_NAME)
	skaffold config unset default-repo
	skaffold config unset insecure-registries
	skaffold config unset kind-disable-load
	skaffold config unset local-cluster
	kubectl config unset contexts.kind-${cluster_name}