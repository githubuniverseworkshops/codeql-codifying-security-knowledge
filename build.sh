git clone https://github.com/xwiki/xwiki-platform.git
pushd xwiki-platform && git checkout xwiki-platform-12.8 && popd
wget https://github.com/github/codeql-cli-binaries/releases/download/v2.14.5/codeql-linux64.zip
unzip codeql-linux64.zip

export PATH=$PATH:$PWD/codeql

codeql database create --language java --source-root xwiki-platform xwiki-platform-db
codeql database bundle -o /data/xwiki-platform-db.zip xwiki-platform-db
chown 1000:1000 /data/xwiki-platform-db.zip