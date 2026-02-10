CREATE_KEY_PAIR=true
PEM_KEY_NAME="$APP_NAME.$AWS_REGION.$AWS_PROFILE"
PEM_KEY_PATH="keypairs/$PEM_KEY_NAME.pem"
PEM_KEY_REALPATH=$(realpath "$PEM_KEY_PATH")
if $CREATE_KEY_PAIR; then
  if aws ec2 describe-key-pairs \
      --query "KeyPairs[?KeyName=='$PEM_KEY_NAME']" \
      --output text | grep -q "$PEM_KEY_NAME"; then
    echo "✅ El key pair existe"
  else
    echo "❌ El key pair NO existe"
    aws ec2 create-key-pair \
      --key-name "$PEM_KEY_NAME" \
      --query 'KeyMaterial' \
      --output text > "$PEM_KEY_PATH"
  fi
fi
chmod 600 "$PEM_KEY_REALPATH"