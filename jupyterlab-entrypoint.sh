#!/usr/bin/env bash
set -eo pipefail

export RENKU_SESSION_IP=${RENKU_SESSION_IP:-0.0.0.0}
export RENKU_SESSION_PORT=${RENKU_SESSION_PORT:-8000}
export RENKU_BASE_URL_PATH=${RENKU_BASE_URL_PATH:-/}
export RENKU_WORKING_DIR=${RENKU_WORKING_DIR:-/workspace}
export RENKU_MOUNT_DIR=${RENKU_MOUNT_DIR:-${RENKU_WORKING_DIR}}

export HOME=$(eval echo "~$(id -nu)")
#ensure bashrc is sourced
# shellcheck source=/dev/null
source "${HOME}"/.bashrc

jupyter labextension disable "@jupyterlab/apputils-extension:announcements"
jupyter kernelspec remove -f python3

if [ -d ${RENKU_MOUNT_DIR}/.venv ] && \
   ([ "$(readlink ${RENKU_MOUNT_DIR}/.venv/bin/python 2>/dev/null)" != "$(which python 2>/dev/null)" ] || \
    [ "$(grep "version = " ${RENKU_MOUNT_DIR}/.venv/pyvenv.cfg 2>/dev/null | cut -d' ' -f3)" != "$(python --version 2>/dev/null | cut -d' ' -f2)" ]); then
    echo "Virtualenv exists but has mismatch - recreating..."
    rm -rf ${RENKU_MOUNT_DIR}/.venv
fi
python -m venv --system-site-packages ${RENKU_MOUNT_DIR}/.venv
base_site_packages="$(python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')"
derived_site_packages="$(${RENKU_MOUNT_DIR}/.venv/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')"
echo "$base_site_packages" > "$derived_site_packages"/_base_packages.pth
if !(grep "source ${RENKU_MOUNT_DIR}/.venv/bin/activate" ${HOME}/.bashrc); then
  printf "source ${RENKU_MOUNT_DIR}/.venv/bin/activate" >>  ${HOME}/.bashrc
fi
source ${RENKU_MOUNT_DIR}/.venv/bin/activate
if python -c "import ipykernel" >/dev/null 2>&1;then
  python -m ipykernel install --user --name Python3
fi


cd ${RENKU_MOUNT_DIR}

jupyter lab \
	--ip "${RENKU_SESSION_IP}" \
	--port "${RENKU_SESSION_PORT}" \
	--ServerApp.base_url "$RENKU_BASE_URL_PATH" \
	--IdentityProvider.token "" \
	--ServerApp.password "" \
	--ServerApp.allow_remote_access true \
	--ContentsManager.allow_hidden true \
	--ServerApp.root_dir "${RENKU_WORKING_DIR}" \
	--KernelSpecManager.ensure_native_kernel False
