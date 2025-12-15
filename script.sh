#!/usr/bin/env bash

echo "Starting main script..."

# Clean the environment
module purge

# load the user's supplied jupyter setup script
source ~/jupyter.sh

# Set working directory to notebook root directory
cd "${NOTEBOOK_ROOT}"

# Launch the Jupyter server
set -x
jupyter lab --config="${CONFIG_FILE}"
