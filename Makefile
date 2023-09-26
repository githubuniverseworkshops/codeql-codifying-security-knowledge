#all: xwiki-platform-CVE-2021-21380.zip
all: xwiki-platform-db.zip

xwiki-platform-db.zip:
	docker run --rm -it -v $(PWD):/data --entrypoint "/bin/bash" xwiki/build -- /data/build.sh
	