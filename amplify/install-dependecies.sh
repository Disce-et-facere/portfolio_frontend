# install-dependencies.sh
for dir in amplify/functions/*; do
  if [ -d "$dir" ]; then
    echo "Installing dependencies for $dir..."
    cd "$dir"
    npm install aws-sdk
    cd -
  fi
done