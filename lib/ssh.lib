#!/bin/bash
# __SP_application: ssh.lib
# __SP_version: 1
# __SP_runtime: bash
# __SP_api_version: 2
#


# login -------------------------------------------------------------------------
function __SP_sshlogin() {
  name=$(basename ${0})
  host="${1:-default}"
  force="${2:-0}"

  host_info="${shellpack_hosts}/${host}"
  if ! test -r "${host_info}" ; then
    errmsg "no host config for ${host} in ${shellpack_hosts}"
    return 1
  fi

  . ${host_info}

  lock="${host}.${name}.${shellpack_lckext}"

  if ${force} ; then
    delete_lock ${lock}
  fi

  ssh_opt="${SSH_OPT}"
  first=false
  if ! test -z "${SSH_PROXY}" ; then
    if create_lock "${lock}" ; then
      first=true
      ssh_opt="${ssh_opt} ${SSH_PROXY}"
      print_into_lock "${lock}" "SSH_OPT=\"${ssh_opt}\""
    else
      echo "proxies are active"
    fi
  fi

  host_key="${shellpack_keys}/${host}.${shellpack_sshkeyext}"
  if test -r "${host_key}" ; then
    ssh_opt="${ssh_opt} -i ${host_key}"
  fi

  user=${SSH_USER:-${USER}}
  echo "Login to ${user}@${FQDN}"

  ${ssh_bin} ${ssh_opt} ${user}@${FQDN}
  ret=$?
  if ${first} ; then
    delete_lock "${lock}"
  fi
  return ${ret}
} # end __SP_ssh_login


# scp ---------------------------------------------------------------------------
function __SP_sshpush() {
  name=$(basename ${0})
  host="${1:-default}"
  host_info="${shellpack_hosts}/${host}"

  if ! test -r "${host_info}" ; then
    errmsg "no host config for ${host} in ${shellpack_hosts}"
    return 1
  fi

  . ${host_info}

  file="${2}"
  if ! test -r "${file}" ; then
    errmsg "file not found: ${file}"
    return 2
  fi

  scp_opt="${SCP_OPT}"
  host_key="${shellpack_keys}/${host}.${shellpack_sshkeyext}"
  if test -r "${host_key}" ; then
    scp_opt="${scp_opt} -i ${host_key}"
  fi

  user=${SSH_USER:-${USER}}
  push_def="/home/${user}"
  push_dir=${SCP_REMOTE:-${push_def}}

  echo "Copying ${file} to ${user}@${FQDN}:${push_dir}"    
  ${scp_bin} ${scp_opt} ${file} ${user}@${FQDN}:${push_dir}
  return $?
} # end __SP_sshpush


function __SP_sshpop() {
  name=$(basename ${0})
  host="${1:-default}"
  host_info="${shellpack_hosts}/${host}"

  if ! test -r "${host_info}" ; then
    errmsg "no host config for ${host} in ${shellpack_hosts}"
    return 1
  fi

  . ${host_info}

  file="${2}"

  scp_opt="${SCP_OPT}"
  host_key="${shellpack_keys}/${host}.${shellpack_sshkeyext}"
  if test -r "${host_key}" ; then
    scp_opt="${scp_opt} -i ${host_key}"
  fi

  user=${SSH_USER:-${USER}}
  pop_def="/home/${user}"
  pop_dir=${SCP_REMOTE:-${pop_def}}

  pop_local_def="${HOME}"
  pop_local=${SCP_LOCAL:-${pop_local_def}}

  if ! test -d ${pop_local} ; then
    mkdir -p ${pop_local}
  fi

  echo "Copying ${user}@${FQDN}:${pop_dir}/${file} to ${pop_local}"
  ${scp_bin} ${scp_opt} ${user}@${FQDN}:${pop_dir}/${file} ${pop_local}
  return $?
} # end __SP_sshpop


# mount -------------------------------------------------------------------------
function __SP_sshmount() {
  name=$(basename ${0})
  host="${1:-default}"
  host_info="${shellpack_hosts}/${host}"

  if ! test -r "${host_info}" ; then
    errmsg "no host config for ${host} in ${shellpack_hosts}"
    return 1
  fi

  . ${host_info}

  sshfs_opt="${SSHFS_OPT}"
  host_key="${shellpack_keys}/${host}.${shellpack_sshkeyext}"
  if test -r "${host_key}" ; then
    sshfs_opt="${sshfs_opt} -o IdentityFile=${host_key}"
  fi

  sshfs_local_def="${HOME}/remote/${host}"
  sshfs_local=${SSHFS_LOCAL:-${sshfs_local_def}}

  user=${SSH_USER:-${USER}}

  sshfs_remote_def="/home/${user}"
  sshfs_remote=${SSHFS_REMOTE:-${sshfs_remote_def}}

  create_directory "${sshfs_local}"

  echo "Mounting ${user}@${FQDN}:${sshfs_remote} to ${sshfs_local}"
  ${sshfs_bin} ${user}@${FQDN}:${sshfs_remote} ${sshfs_local} ${sshfs_opt}
  return $?
} # end __SP_sshmount


function __SP_sshumount() {
  name=$(basename ${0})
  host="${1:-default}"
  host_info="${shellpack_hosts}/${host}"

  if ! test -r "${host_info}" ; then
    errmsg "no host configuration for ${host} in ${shellpack_hosts}"
    return 1
  fi

  . ${host_info}

  sshfs_local_def="${HOME}/remote/${host}"
  sshfs_local=${SSHFS_LOCAL:-${sshfs_local_def}}

  ${fusermnt_bin} ${fusermnt_opts} ${sshfs_local}
  return $?
} # end __SP_sshumount


# ssh misc ----------------------------------------------------------------------
function __SP_sshkeygen() {
  name=$(basename ${0})
  host="${1:-default}"
  force="${2:-0}"

  cd ${shellpack_keys}
  key=${host}.id_rsa
  lnkey=${host}.${shellpack_sshkeyext}

  ${keygen_bin} -b 2048 -t rsa -f ${key}
  ret=$?

  if test ${ret} -eq 0 ; then
    chmod go-rwx ${key}
    chmod go-rwx ${key}.pub
    create_symlink "${key}" "${lnkey}"
  else
    return ${ret}
  fi
} # end __SP_sshkeygen
