# API and Routes Documentation

This API broadly conforms the [JSON:API Specifications](https://jsonapi.org/). The major deviations are:
1. The resource's `id` are alphanumeric and are quasi dependent on the attributes,
2. The `files` resources are "transient" and are not directly created or destroyed

## Clusters

### ID

As the API only supports a single cluster, the ID is always `default`

### List

Return the single cluster as a list when in `upstream` mode. The list will be empty in `standalone` mode.

```
GET /clusters
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Default-Cluster-Resource-Object>],
  ... see JSON:API spec ...
}
```

### Show

Request the cluster when in `upstream` mode. This will respond with a `404` when in standalone mode.

```
GET /clusters/default
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "clusters",
    "id": "default",
    "attributes": {
      "name": "default",
    },
    "links": ... see spec ...

  }, ... see spec ...
}
```

## Groups

### ID

The ID for `group` is always the same as it's name. This means it is alphanumeric and may contain `-` and `_`.

### List

Return a list of available `groups` when in `upstream` mode. Returns an empty list in standalone mode as groups are disabled.

```
GET /groups
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Array-Of-Group-Resource-Object>],
  ... see JSON:API spec ...
}
```

### Show

Return a single `group` by its ID. This will always respond `Not Found` in `standalone` mode.

```
GET /groups/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "groups",
    "id": ":id",
    "attributes": {
      "name": ":id",
    },
    "links": ... see spec ...

  }, ... see spec ...
}
```

## Nodes

### ID

The ID for a `node` is always the same as the it's name. This means it is alphanumeric and may contain `-` and `_`.

### List

Return a list of the available `nodes`.

```
GET /nodes
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Array-Of-Node-Resource-Object>],
  ... see JSON:API spec ...
}
```

### Show

Return a single `group` by its ID

```
GET /nodes/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "nodes",
    "id": ":id",
    "attributes": {
      "name": ":id",
    },
    "links": ... see spec ...

  }, ... see spec ...
}
```

## Templates

### ID

The ID for a `template` is its file `name`. It must be an alphanumeric string but MAY also contain the following characters: `-_.`.

### List

Return a list of the available `templates`:

```
GET /templates
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [<Array-Of-Templates-Resource-Object>],
  ... see JSON:API spec ...
}
```

### Show

Return a single `template` by its ID

```
GET /templates/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "templates",
    "id": "<name>",
    "attributes": {
      "name": "<name>",
      "payload": "<payload>"
    },
    "links": ... see spec ...
  }, ... see spec ...
}
```

### Create

Create a new `template` resource with a unique `name`. An error will be raised if the `name` has already been taken. The optional `payload` field should given the content of the template. A blank template will be created if it is omitted.

```
POST /templates
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": {
    "type": "templates",
    "attributes": {
      "name": "<name>",
      "payload": "<payload>"
    }
  }
}

HTTP/1.1 201 CREATED
Content-Type: application/vnd.api+json
{
  "data": <New-Template-Resource-Object>,
  ... see spec ...
}
```

### Update

Update an existing `template` resource's `payload`. The `name` can not be modified as it is used as the `id`. The `template` must exist before it can be updated.

```
PATCH /templates/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": {
    "type": "templates",
    "attributes": {
      "payload": "<payload>"
    }
  }
}

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": <Updated-Template-Resource-Object>,
  ... see spec ...
}
```

### Destroy

Delete a `template` resource by its ID. The `template` must exist before it can be deleted.

```
DELETE /templates/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 204 OK
```

## Files

The `files` resources provide the rendering capability and as such represent a relationship between a `context` and a `template`. The `context` MUST be a `cluster`, `group`, or `node`.

As they represent a possible "relationship" between the `context` and `template`, they are quasi-immuntable and ephemeral. They can not be directly created, updated, or destroyed. Instead they may be modified by preforming a write/delete action on any of the contexts/templates.

### ID

The `file` ID must encode the IDs for the `context` and `template` and may take one of the following forms:

```
# Cluster Context
<template-name>.default.clusters

# Group Context
<template-name>.<group-name>.groups

# Node Context
<template-name>.<group-name>.nodes
```

### List

The generic list `templates` request will always return an empty set. This is because the complete list of `files` is likely very large and MUST not be returned by default.

```
GET /files
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [],
  ... see spec ...
}
```

#### Selecting (aka Filtering)

In order to "select" any `files` to be returned, the `index` request must be combined with the `filter` parameter. The mandatory `ids` filter MUST be sent with the request AND at least one additional filter MUST be supplied.

The first mandatory parameter is `filter[ids]` which MUST give a comma separated list of the `template` ids. This filter selects which templates should be rendered but does not provide the any `context`. When used individually it MUST return an empty array.

```
GET /files?filter[ids]=<csv-template-ids>
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [],
  ... see spec ...
}
```

The subsequent `filter` queries are used to select the `contexts`. They maybe one or more of the following:
* `filter[node.ids]=<csv-node-ids>`:        Select multiple `nodes` to be rendered
* `filter[node.group-ids]=<csv-group-ids>`: Select all the `nodes` in multiple groups to be rendered,
* `filter[node.all]=true`:                  Select all the `nodes` in the cluster to be rendered,
* `filter[group.ids]=<csv-group-ids>`:      Select multiple `groups` to be rendered,
* `filter[group.all]=true`:                 Select all the `groups` in the cluster to be rendered,
* `filter[cluster]=true`:                   Select the `cluster` to be rendered against.

*NOTE*: The `node.group-ids` and `group.ids` are different filters and can not be used interchangeably. `node.group-ids` will cause the `template` to be rendered against the `node` resource that just happen to be within a `group`. Where `group.ids` will render the `template` against the `group` itself. As `nodes` and `groups` maintain independent parameter sets, this will return different results.

As the above filters only select the `contexts` to be rendered against they will all return an empty array when used in isolation.

```
GET /files?filter[node.ids]=<csv-node-ids>
GET /files?filter[node.group-ids]=<csv-group-ids>
GET /files?filter[node.all]=true
GET /files?filter[group.ids]=<csv-group-ids>
GET /files?filter[group.all]=true
GET /files?filter[cluster]=true
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [],
  ... see spec ...
}
```

The `index` action SHOULD then combine the `ids` filter one or more `context` filters:

```
GET /files?filter[ids]=<csv-template-ids>&filter[node.ids]=<csv-node-ids>
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": [
    <File-Resource-Object>,
    ...
  ],
  ... see spec ...
}
```

### Show

A rendered file can be retrieved directly by its `ID`. The `context` and `template` must already exist before hand.

```
GET /files/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>

HTTP/1.1 200 OK
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "files",
    "id": "<id>",
    "attributes": {
      "payload": "<rendered-template-payload>"
    },
    "relationships": {
      "template": {
        "data": <Template-Resource-Identifier-Object>,
        "links": ... see spec ...
      },
      "context": {
        "data": <Cluster-Group-Or-Node-Resource-Identifier-Object>,
        "links": ... see spec ...
      }
    },
    "links": ... see spec ...
  }, ... see spec ...
}
```

### Create

This method "creates" an ephemeral `file` resource. It only lives as long as the request is active. It does not permanently save the `template` or `file`.

Instead it used to render for a single context without having to upload a
template. Instead the `template` key must contain the string to be rendered.

*NOTE*: As this method only "creates" an ephemeral resource, it is considered a
read action. As such a `user_token` can be used with this request.

```
POST /files/:id
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
Authorization: Bearer <jwt>
{
  "data": {
    "type": "files",
    "attributes": {
      "template": "<source-template>"
    },
    "relationships": {
      "context": {
        "data": <Cluster-Group-Or-Node-Resource-Identifier-Object>
      }
    },
    "links": ... see spec ...
  }, ... see spec ...
}

HTTP/1.1 201 CREATED
Content-Type: application/vnd.api+json
{
  "data": {
    "type": "files",
    "id": "<id>",
    "attributes": {
      "payload": "<rendered-template-payload>"
    },
    "relationships": {
      "template": {
        "data": <Template-Resource-Identifier-Object>,
        "links": ... see spec ...
      },
      "context": {
        "data": <Cluster-Group-Or-Node-Resource-Identifier-Object>,
        "links": ... see spec ...
      }
    },
    "links": ... see spec ...
  }, ... see spec ...
}
```

