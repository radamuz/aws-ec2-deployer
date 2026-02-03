ssh -i $PEM_KEY_REALPATH ubuntu@$PUBLIC_IP "mkdir -p ~/$APP_NAME"
scp -i "$PEM_KEY_REALPATH" "tars/$DOCKERFILE_NAME.arm64.tar" ubuntu@"$PUBLIC_IP":~/$APP_NAME
scp -i "$PEM_KEY_REALPATH" "dockerfiles/$DOCKERFILE_NAME/docker-compose.yml" ubuntu@"$PUBLIC_IP":~/$APP_NAME
ssh -t -i $PEM_KEY_REALPATH ubuntu@$PUBLIC_IP "docker load -i ~/$APP_NAME/$DOCKERFILE_NAME.arm64.tar"
ssh -t -i $PEM_KEY_REALPATH ubuntu@$PUBLIC_IP "cd ~/$APP_NAME && docker compose up -d"