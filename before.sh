# Export the module function if it exists
[[ $(type -t module) == "function" ]] && export -f module

# purge any loaded modules
module purge

# Find available port to run server on
port=$(find_port ${host})

# Generate SHA1 encrypted password (requires OpenSSL installed)
SALT="$(create_passwd 16)"
password="$(create_passwd 16)"
PASSWORD_SHA1="$(echo -n "${password}${SALT}" | openssl dgst -sha1 | awk '{print $NF}')"

# Safari users hit this error https://github.com/jupyterlab/jupyterlab/issues/5486
# so let's make a new workspace dir that's this job's PWD and copy the default /lab
# workspace over there so folks can update it.
WORKSPACE_DIR="$HOME/.jupyter/lab/workspaces"
FILES=$(ls $WORKSPACE_DIR 2> /dev/null)

for FILE in ${FILES[@]}
do
  ID=$(jq -r '.metadata.id' $WORKSPACE_DIR/$FILE)

  if [[ $ID == "/lab" ]]; then
    WORKSPACE_FILE="$WORKSPACE_DIR/$FILE"
    break
  fi
done

if [[ ${WORKSPACE_FILE+x} ]]; then
  cp $WORKSPACE_FILE .
fi

# set the jupyter mode: either lab or notebook aka tree
JUPYTER_API="lab"
export jupyter_api="$JUPYTER_API"

# configure workspaces dir for jupyter lab
export JUPYTERLAB_WORKSPACES_DIR=$PWD

# Notebook root directory

export NOTEBOOK_ROOT="$(readlink -f /users/sansom/mat611/devel/venv/reporting)"


# The `$CONFIG_FILE` environment variable is exported as it is used in the main
# `script.sh.erb` file when launching the Jupyter server.
export CONFIG_FILE="${PWD}/config.py"
# Generate Jupyter configuration file with secure file permissions
(
umask 077
cat > "${CONFIG_FILE}" << EOL
c.KernelSpecManager.ensure_native_kernel = False
c.ServerApp.ip = '*'
c.ServerApp.port = ${port}
c.ServerApp.base_url = '/node/${host}/${port}/'
c.ServerApp.port_retries = 0
c.ServerApp.PasswordIdentityProvider.hashed_password = u'sha1:${SALT}:${PASSWORD_SHA1}'
c.ServerApp.password_required = True
c.ServerApp.allow_origin = '*'
c.ServerApp.root_dir = '${NOTEBOOK_ROOT}'
c.ServerApp.disable_check_xsrf = True
c.NotebookApp.open_browser = False
EOL
)
