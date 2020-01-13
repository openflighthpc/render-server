[![Build Status](https://travis-ci.org/openflighthpc/render-server.svg?branch=master)](https://travis-ci.org/openflighthpc/render-server)

# Render Server

Shared micro-service that renders files for a cluster, groups, and nodes

## Installation

### Preconditions

The following are required to run this application:

* OS:           Centos7
* Ruby:         2.5+
* Yum Packages: gcc

### Manual installation

Start by cloning the repo, adding the binaries to your path, and install the gems. This guide assumes the `bin` directory is on your `PATH`. If you prefer not to modify your `PATH`, then some of the commands need to be prefixed with `/path/to/app/bin`.

```
git clone https://github.com/openflighthpc/render-server
cd render-server

# Add the binaries to your path, which will be used by the remainder of this guide
export PATH=$PATH:$(pwd)/bin
bundle install --without development test --path vendor

# The following command can be ran without modifying the PATH variable by
# prefixing `bin/` to the commands
bin/bundle install --without development test --path vendor
```

### Configuration

The main configuration value required by the server directly is the `jwt_shared_secret`. This must be exported into the environment.

```
export jwt_shared_secret=<keep-this-secret-safe>
```

The server can the either operate in `standalone` or `upstream` mode. Standalone mode allows `render-server` to operate by itself without integrating with other `OpenFlightHPC` services. The `upstream` mode integrates with `nodeattr-server` for the `cluster`, `groups`, and `nodes` configuration values.

#### Upstream Mode

Two configuration values need to be exported into the environment in order to put the server in `upstream` mode: `remote_url` and `remote_jwt`. The `remote_url` should specify where the upstream server is being hosted and `remote_jwt` is the access token to the server.

*NOTE*: It is highly recommended that `remote_jwt` is a "user token" as `render-server` only needs read access in a production environment. This will inhibit the development `rake` tasks which preform write/delete requests. Extreme caution must be taken when running `rake` tasks with an "admin token".

Whilst `nodeattr-server` fully supports multiple clusters, `render-server` does not. Instead `render-server` will operate on the cluster called `default`. This can be changed by setting the `remote_cluster` environment variable.

*NOTE*: Whilst `remote_cluster` can be configured to any upstream `nodeattr-server` cluster, the `render-server` API will always refer to it as "default". See full [API specifications](docs/routes.md) for further details.

```
export remote_url=<upstream-url>
export remote_jwt=<upstream-user-token>

# Optional
export remote_cluster=<upstream-cluster-name | default>
```

#### Standalone Mode

Standalone mode is activated by default as `remote_url` has not been set. The `cluster` and `groups` functionality is disabled when in standalone mode. Any requests for clusters/groups will result in a `Not Found` error, or will be ignored (see [api specification](docs/routes.md) for further details).

Instead the `nodes` list will be loaded from the "topology". The path to the `topology_config` is configurable as either an absolute or relative path to the install directory ([see for further details](config/application.yaml.reference)). By default it will be loaded from: `config/topology.yaml`.

The following will explicitly set the server into `standalone` mode.
NOTE: It will implicitly use these settings when `remote_url` is not set

```
unset remote_url
export topology_config=config/topology.yaml

cat <<'EOF' >config/topology.yaml
... Topology Config Content ...
EOF
```

An example topology config could look like:

```
nodes:
  node01:
    role: compute
    ip:   10.101.0.1
  <node-id>:
    <param-key>: <value>
    ...
  ...
```

### Integrating with systemd and OpenFlightHPC/FlightRunway

The [provided systemd unit file](support/render-server.service) has been designed to integrate with the `OpenFlightHPC` [flight-runway](https://github.com/openflighthpc/flight-runway) package. The following preconditions must be satisfied for the unit file to work:
1. `OpenFlightHPC` `flight-runway` must be installed,
2. The server must be installed within `/opt/flight/opt/render-server`,
3. The log directory must exist: `/opt/flight/log`, and
4. The configuration file must exist: `/opt/flight/etc/render-server.conf`.

The configuration file will be loaded into the environment by `systemd` and can be used to override values within `config/application.yaml`. This is the recommended way to set the custom configuration values and provides the following benefits:
1. The config will be preserved on update,
2. It keeps the secret keys separate from the code base, and
3. It eliminates the need to source a `bashrc` in order to setup the environment.

## Starting the Server

The `puma` server daemon can be started manually with:

```
bin/puma -p <port> -e production -d \
          --redirect-append \
          --redirect-stdout <stdout-log-file-path> \
          --redirect-stderr <stderr-log-file-path>
```

## Stopping the Server

The `pumactl` command can be used to preform various start/stop/restart actions. Assuming that `systemd` hasn't been setup, the following will stop the server:

```
bin/pumactl stop
```

## Authentication

The API requires all requests to carry with a [jwt](https://jwt.io). Admin tokens must set the `admin` flag to `true` within their body. All other valid tokens are assumed to have `user` level privileges. Admins have full `read`/`write` access, where a `user` only has `read` access.

The following `rake` tasks are used to generate tokens with 30 days expiry. Tokens from other sources will be accepted as long as they:
1. Where signed with the same shared secret,
2. An [expiry claim](https://tools.ietf.org/html/rfc7519#section-4.1.4) has been made.

As the shared secret is environment dependant, the `RACK_ENV` must be set within your environment.

```
# Set the rack environment
export RACK_ENV=production

# Generate a user token
rake token:admin    # Valid for 30 days [Default]
rake token:admin[1] # Valid for 1 day   [Smallest]

# Generate a user token
rake token:user       # Valid for 30 days [Default]
rake token:user[360]  # Valid for 360 days
```

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see LICENSE.txt for details.

Copyright (C) 2020-present Alces Flight Ltd.

This program and the accompanying materials are made available under the terms of the Eclipse Public License 2.0 which is available at https://www.eclipse.org/legal/epl-2.0, or alternative license terms made available by Alces Flight Ltd - please direct inquiries about licensing to licensing@alces-flight.com.

RenderServer is distributed in the hope that it will be useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more details.
