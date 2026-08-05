# Shell Idempotency Patterns

## Create if Not Exists
```bash
# Directory
if [[ ! -d "/opt/example/config" ]]; then
    mkdir -p "/opt/example/config"
fi

# File
if [[ ! -f "/etc/example/config.yaml" ]]; then
    cp /templates/config.yaml /etc/example/config.yaml
fi
```

## Check Before Action
```bash
# AWS resource exists?
if aws s3 ls "s3://${bucket}" 2>/dev/null; then
    echo "Bucket exists: ${bucket}"
else
    aws s3 mb "s3://${bucket}"
fi

# Docker container running?
if docker ps -q --filter "name=${name}" | grep -q .; then
    docker stop "${name}"
fi
```

## Safe Delete
```bash
# Never rm -rf without explicit path
readonly BASE="/opt/example"
if [[ "${target}" == /opt/example/* ]] && [[ -d "${target}" ]]; then
    rm -rf "${target}"
fi

# Safe file removal
if [[ -f "${file}" ]]; then
    rm "${file}"
fi
```

## Migration Pattern
```bash
# Run migration only if not applied
run_migration() {
    local version="${1}"
    if grep -q "${version}" /var/example/migrations.log 2>/dev/null; then
        echo "Migration ${version} already applied"
        return 0
    fi
    echo "Running migration ${version}..."
    # do migration
    echo "${version}" >> /var/example/migrations.log
}
```
