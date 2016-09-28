# Logstash Buildpack for Cloud Foundry

This buildpack allows to deploy [Logstash](https://www.elastic.co/products/logstash) as an app in Cloud Foundry.

## Usage

### Logstash Cloud Foundry App

A Logstash Cloud Foundry App has the following structure:

```
.
├── conf.d
│   ├── filter.conf
│   ├── input.conf
│   └── output.conf
├── grok-patterns
│   └── grok-patterns
├── Logstash
└── manifest.yml
```

#### Logstash

The `Logstash` file in the root directory of the app is required. It is used by the buildpack to detect if the app is in fact a 
Logstash app. Furthermore it allows to configure the buildpack / the deployment of the app. The `Logstash` file is sourced during deployment
so it has to be valid `bash` code to work.

The follow settings are allowed:

* `LOGSTASH_VERION`: Version of Logstash to be deployed
* `LOGSTASH_CMD_ARGS`: Additional command line arguments for Logstash
* `LOGSTASH_PLUGINS`: Array of Logstash plugins, which are not provided with the default Logstash, but are installable by `logstash-plugin`.
* `LOGSTASH_CONFIG_CHECK`: Boolean (0/1) if a pre-flight-check should be performed with the Logstash configuration during app deployment.
* `LS_HEAP_SIZE`: Heap size for Logstash. By defaults to 90% of the app memory limit.

Example file:

```
# Configuration-file for Logstash Cloud Foundry Buildpack

LOGSTASH_VERSION="2.4.0"
LOGSTASH_CMD_ARGS=""
LOGSTASH_PLUGINS=(
	"logstash-codec-cef"
)
LOGSTASH_CONFIG_CHECK=1
LS_HEAP_SIZE=500m
```

#### manifest.yml

This is the [Cloud Foundry application manifest](https://docs.cloudfoundry.org/devguide/deploy-apps/manifest.html) file which is used by `cf push`.

This file may be used to set environment variables (see next section).

If the special environment variable `DEBUG` is set to `1`, debug output is given during the app deployment.

#### conf.d

In the folder `conf.d` the Logstash configuration is provided. The folder it self and at least one configuration file is required for Logstash
to be deployed successfully. All files in this directory are used as part of the Logstash configuration.
Prior to the start of Logstash, all files in this directory are processed by [dockerize](https://github.com/jwilder/dockerize) as templates.
This allow to update the configuration files based on the environment variables provided by Cloud Foundry (e.g. VCAP_APPLICATION, VCAP_SERVICES).

The supported functions for the templates are documented in [dockerize - using templates](https://github.com/jwilder/dockerize/blob/master/README.md#using-templates) 
and [golang - template](https://golang.org/pkg/text/template/).

#### grok-patterns (and other 3rd party configuration)

You may provide additional configuration files like grok-patterns or useragent regexes in additional directories. To provide the correct path within the Logstash
configuration, it's suggested to set the paths by the template engine. Example (use all grok patterns in directory `grok-patterns`):

```
patterns_dir => "{{ .Env.HOME }}/grok-patterns"
```

