# http://testsuite.appleseedhq.net:8181/

set -x

docker container stop automated-test-suite-container
docker container rm automated-test-suite-container

docker run --name automated-test-suite-container \
	--network host \
	-v /home/johnny/automated-test-suite-www:/var/www:ro \
	-v /home/johnny/automated-test-suite/webserver_nginx_conf:/etc/nginx/conf.d:ro \
	-p 8080:8080 \
 	-d nginx:alpine

