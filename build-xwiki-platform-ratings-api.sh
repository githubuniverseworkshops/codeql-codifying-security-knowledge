git clone https://github.com/xwiki/xwiki-platform.git
pushd xwiki-platform && git checkout xwiki-platform-12.8 && popd
wget https://github.com/github/codeql-cli-binaries/releases/download/v2.14.5/codeql-linux64.zip
unzip codeql-linux64.zip

export PATH=$PATH:$PWD/codeql

codeql database create --language java --source-root xwiki-platform --command="mvn clean package -Dfindbugs.skip -Dcheckstyle.skip -Dpmd.skip=true -Dspotbugs.skip -Denforcer.skip -Dmaven.javadoc.skip -DskipTests -Dmaven.test.skip.exec -Dlicense.skip=true -Drat.skip=true -Dspotless.check.skip=true -pl :xwiki-platform-ratings-api" xwiki-platform-ratings-api-12.8-db
codeql database bundle -o /data/xwiki-platform-ratings-api-12.8-db.zip xwiki-platform-ratings-api-12.8-db
chown 1000:1000 /data/xwiki-platform-ratings-api-12.8-db.zip