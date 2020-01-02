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

Request the cluster when in `upstream` mode. 

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

Return a list of available `groups` when in `upstream` mode. Groups are not available when in standalone mode.

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

Return a single `group` by its ID

```
GET //:id
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

The `templates` use a composite ID which takes the form of: `<name>.<type>`. Both the `name` and `type` must be alphanumeric and may contain `-` and `_`. As the `name` and `type` are used to generate the `ID`, they are static to the template and can not be modified post creation.

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
    "id": "<id>",
    "attributes": {
      "name": "<name>",
      "type": "<type>",
      "payload": "<payload>"
    },
    "links": ... see spec ...
  }, ... see spec ...
}
```

### Create

Create a new `template` resource with a unique `type` and `name` combination. An error will be raised if the `type`/`name` pair has already been taken. The optional `payload` field should given the content of the template. A blank template will be created if it is omitted.

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
      "type": "<type>",
      "payload": "<payload>"
    }a
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

Update an existing `template` resource's `payload`. As the `name` and `type` are used to generate the `id`, they can not be modified. The `template` must exist before it can be updated.

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
    }a
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

