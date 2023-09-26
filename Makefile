all: xwiki-platform-12.8-db.zip xwiki-platform-ratings-api-12.8-db.zip


xwiki-platform-12.8-db.zip:
	docker run --rm -it -v $(PWD):/data --entrypoint "/bin/bash" xwiki/build -- /data/build-xwiki-platform.sh
	
xwiki-platform-ratings-api-12.8-db.zip:
	docker run --rm -it -v $(PWD):/data --entrypoint "/bin/bash" xwiki/build -- /data/build-xwiki-platform-ratings-api.sh