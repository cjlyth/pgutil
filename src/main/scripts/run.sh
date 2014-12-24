#!/usr/bin/env bash


ENVFILE=${ENVFILE:-/tmp/pdb.env}

[[ -s "${ENVFILE}" ]] || {
	echo "creating: ${ENVFILE}"
	cat <<-'EOF' > ${ENVFILE}
		PGPORT=5432
		PGDATABASE=publicrelay
		PGUSER=postgres
		POSTGRES_USER=postgres
		PGPASSWORD=postgres
		POSTGRES_PASSWORD=postgres
EOF
}

function is_paused()
{
	[[ ! -z "$(docker ps -aq -f name=pdb -f status=paused)" ]]
}

function is_exited()
{
	[[ ! -z "$(docker ps -aq -f name=pdb -f status=exited)" ]]
}
function is_running()
{
	[[ ! -z "$(docker ps -aq -f name=pdb -f status=running)" ]]
}

function is_restarting()
{
	[[ ! -z "$(docker ps -aq -f name=pdb -f status=restarting)" ]]
}
function start_db()
{
	docker run -p 5432:5432 \
		--restart=always \
		--name=pdb \
		--hostname=pdb \
		--env-file="${ENVFILE}" \
		-d postgres
}

is_paused || is_exited || is_running || is_restarting || {
	echo "Creating container 'pdb'"
	start_db >/dev/null
}

is_paused && {
	echo "Un-pausing container 'pdb'"
	docker unpause pdb >/dev/null
}
is_exited && {
	echo "Starting container 'pdb'"
	docker start pdb >/dev/null
}
is_restarting && {
	echo "Container 'pdb' is restarting, unable to proceed"
	exit 1
}
is_running || {
	echo "Container 'pdb' is not running, unable to proceed"
	exit 2
}

function drop_database()
{
# DROP DATABASE IF EXISTS publicrelay;
docker run -t --link pdb:postgres --rm \
	--env-file="${ENVFILE}" \
	postgres sh -c 'exec dropdb -e --if-exists -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" publicrelay'
}
function create_database()
{
# drop_database
#CREATE DATABASE publicrelay TEMPLATE template0;
docker run -t --link pdb:postgres --rm \
	--env-file="${ENVFILE}" \
	postgres sh -c 'exec createdb -e -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -T template0'
}
function postgres_help()
{
docker run -it --link pdb:postgres --rm \
	--env-file="${ENVFILE}" \
	postgres sh -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" --help'
}
function postgres_shell()
{
docker run -it --link pdb:postgres --rm \
	--env-file="${ENVFILE}" \
	-v /Users/cjlyth/aug29a.pgdump:/tmp/pdb.pgdump:ro \
	postgres bash
}
function postgres_restore()
{
docker run -it --link pdb:postgres --rm \
	--env-file="${ENVFILE}" \
	-v /Users/cjlyth/aug29a.pgdump:/tmp/pdb.pgdump:ro \
	postgres sh -c 'exec pg_restore -h "$POSTGRES_PORT_5432_TCP_ADDR" -j 5 -v --no-owner --no-tablespaces --no-privileges --no-security-labels --disable-triggers --dbname publicrelay /tmp/pdb.pgdump'

}

create_database
postgres_restore

exit 0