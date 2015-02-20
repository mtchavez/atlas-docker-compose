# Set up docker defaults
sudo su -c 'sudo cat > /etc/default/docker <<EOF
DOCKER_OPTS="-H 0.0.0.0:2376 --tlsverify=false --tls=false"
EOF'

# Restart docker
sudo service docker restart

