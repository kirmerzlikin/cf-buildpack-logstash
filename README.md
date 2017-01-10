# Logstash Buildpack for Cloud Foundry

**WARNING**: This is work in progress, do not use in production.

This buildpack allows to deploy [Logstash](https://www.elastic.co/products/logstash) as an app in Cloud Foundry.
The buildpack also includes curator, which allows to manage the indices in Elasticsearch.

## Usage

### Logstash Cloud Foundry App

A Logstash Cloud Foundry App has the following structure:

```
.
├── conf.d
│   ├── filter.conf
│   ├── input.conf
│   └── output.conf
├── curator.d
│   ├── actions.yml
│   └── curator.yml
├── grok-patterns
│   └── grok-patterns
├── mappings
│   └── elasticsearch-template.json
├── Logstash
└── manifest.yml
```

#### Logstash

The `Logstash` file in the root directory of the app is required. It is used by the buildpack to detect if the app is in fact a 
Logstash app. Furthermore it allows to configure the buildpack / the deployment of the app. The `Logstash` file is sourced during deployment
so it has to be valid `bash` code to work.

The follow settings are allowed:

* `LOGSTASH_VERION`: Version of Logstash to be deployed. Defaults to 2.4.0
* `LOGSTASH_CMD_ARGS`: Additional command line arguments for Logstash. Empty by default
* `LOGSTASH_PLUGINS`: Array of Logstash plugins, which are not provided with the default Logstash, but are installable by `logstash-plugin`. Empty by default
* `LOGSTASH_CONFIG_CHECK`: Boolean (0/1) if a pre-flight-check should be performed with the Logstash configuration during app deployment. Defaults to `1`
* `LS_HEAP_SIZE`: Heap size for Logstash. By defaults to 90% of the app memory limit
* `CURATOR_ENABLED`: Should curator be enabled (1) or disabled (0)
* `CURATOR_SCHEDULE`: Schedule for curator (when to run curator) in cron like syntax (https://godoc.org/github.com/robfig/cron). Format `second minute hour day_of_month month day_of_week`

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
CURATOR_ENABLED=1
CURATOR_SCHEDULE="0 5 2 * * *"
```

#### manifest.yml

This is the [Cloud Foundry application manifest](https://docs.cloudfoundry.org/devguide/deploy-apps/manifest.html) file which is used by `cf push`.

This file may be used to set environment variables (see next section).

If the special environment variable `DEBUG` is set to `1`, debug output is given during the app deployment.

#### conf.d

In the folder `conf.d` the [Logstash](https://www.elastic.co/guide/en/logstash/current/index.html) configuration is provided. The folder it self and at least one configuration file is required for Logstash
to be deployed successfully. All files in this directory are used as part of the Logstash configuration.
Prior to the start of Logstash, all files in this directory are processed by [dockerize](https://github.com/jwilder/dockerize) as templates.
This allow to update the configuration files based on the environment variables provided by Cloud Foundry (e.g. VCAP_APPLICATION, VCAP_SERVICES).

The supported functions for the templates are documented in [dockerize - using templates](https://github.com/jwilder/dockerize/blob/master/README.md#using-templates) 
and [golang - template](https://golang.org/pkg/text/template/).

#### curator.d

Configuration folder for [curator](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/index.html) containing two files:

* `actions.yml`: General configuration of curator. For details see section [Configuration File](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/configfile.html) in the official documentation.
* `curator.yml`: Definitions of the actions to be executed by curator. For details see section [Action File](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/actionfile.html) in the official documentation.

Both files are processed with [dockerize](https://github.com/jwilder/dockerize). For details see above in the section about the folder `conf.d`.

#### grok-patterns (and other 3rd party configuration)

You may provide additional configuration files like grok-patterns or useragent regexes in additional directories. To provide the correct path within the Logstash
configuration, it's suggested to set the paths by the template engine. Example (use all grok patterns in directory `grok-patterns`):

```
patterns_dir => "{{ .Env.HOME }}/grok-patterns"
```

#### mappings

Optional folder to ship mapping templates for Elasticsearch. These mapping templates could be applied by Logstash. See [logstash-output-elasticsearch](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html) for details.

### Deploy App to Cloud Foundry

To deploy the Logstash app to Cloud Foundry using this buildpack, use the following command:

```
cf push -b https://github.com/swisscom/swisscom/cf-buildpack-logstash.git
```

After the successful upload of the application to Cloud Foundry, you may use a *user provided service* to ship the logs of your
application to your newly deployed Logstash applicationrr.

Create the log drain:

```
cf cups logstash-log-drain -l https://USERNAME:PASSWORD@URL-OF-LOGSTASH-INSTANCE
```

Bind the log drain to your app. You could optionally bind multiple apps to one log drain:

```
cf bind-service YOUR-CF-APP-NAME logstash-log-drain
```

Restage the app to pick up the newly bound service:

```
cf restage YOUR-CF-APP-NAME
```

You find more details in the [Cloud Foundry documentation](https://docs.cloudfoundry.org/devguide/services/log-management.html)

Alternatively the log drain may also be configured in your application manifest as described in chapter [Application Log Streaming](https://docs.cloudfoundry.org/services/app-log-streaming.html).

## Limitations

* This buildpack is only tested on Ubuntu based deployments.