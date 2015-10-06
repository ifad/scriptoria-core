# Scriptoria Core API Docs - Version 1

## Launch a new workflow

    POST /v1/workflows

To launch a workflow, the full process definition should be sent. Process
definitions are not currently stored in the application.

### Parameters

| Parameter | Mandatory | Description              |
|-----------|-----------|--------------------------|
| workflow  | Yes       | Ruote process defintion  |
| callbacks | Yes       | Hash of callback URLs    |

`workflow` is a [process definition](http://ruote.io/definitions.html) in any
format that Ruote will understand (XML, JSON, Radial).

`callbacks` is a hash of callback URLs, where the key is the participant name.

### Example Request

```
curl http://core.dev/v1/workflows \
  -d "workflow=<process-definition name=\"aaa\"><participant ref=\"alpha\" /></process-definition>" \
  -d "callbacks[alpha]=http://localhost:1234/callbacks/alpha"
```

### Example Response

```
HTTP/1.1 201 Accepted
{
  "id": "20151005-1247-kogadeso-gekunute"
}
```

### Errors

An error will be returned if Ruote decides the process definition is invalid.

Note that `callbacks` is not validated to ensure all participants in the
workflow are present - if a participant is reached that does not have a URL the
workflow will raise an error (internally) and halt.

## Receive a participant callback

For each participant that is reached, a callback will be made to the relevant
URL as passed when the callback was created. This contains details of the
current workitem and participant. The application should do whatever work is
required for this partiicpant step (send an email, wait for user input, etc)
and then call the proceed action on the workitem.

If a timeout or error occurs, another callback request will be made with a
`status` of `timeout` or `error`. In this case the application should stop
whatever work it is doing (if possible). Depending on how the workflow is setup
to handle errors, the workitem or entire workflowmay be replayed.

### Parameters

| Parameter    | Mandatory | Description                 |
|--------------|-----------|-----------------------------|
| workflow\_id | Yes       | ID of the workflow          |
| workitem\_id | Yes       | ID of the workitem          |
| participant  | Yes       | Participant name            |
| status       | Yes       | Status of the workitem      |
| fields       | Yes       | Hash of the workitem fields |

`status` can be `active` (the default), `timeout` or `error`.

### Example Request

```
POST /callbacks/alpha
Content-Type: application/json

{
  "workflow_id":"20151005-1247-kogadeso-gekunute",
  "workitem_id":"0_0!023abf5d398319b1c8fcbfaf70e7c780!20151005-1247-kogadeso-gekunute",
  "participant":"alpha",
  "status":"active",
  "fields": {
    "params": {
      "ref": "alpha"
    }
  }
}
```

The application should respond with a 2xx response code. If a 2xx response code
is not received, the request will be retried.

## Proceed a workitem

    POST /v1/workflows/:workflow_id/workitems/:workitem_id/proceed

Once a workitem has been completed the proceed action should be called.

### Parameters

| Parameter | Mandatory | Description                              |
|-----------|-----------|------------------------------------------|
| fields    | Yes       | Hash of fields to be set on the workitem |

`fields` will be merged with existing fields on the workitem. If a field is
already set on the workitem, fields in the `fields` parameter will take
precidence. The fields set here will then be present on subsequent callbacks
requests.

### Example Request

```
curl http://core.dev/v1/workflows/20151005-1247-kogadeso-gekunute/workitems/0_0!023abf5d398319b1c8fcbfaf70e7c780!20151005-1247-kogadeso-gekunute/proceed \
  -d "fields[status]=successful"
```

### Example Response

```
HTTP/1.1 201 Accepted
OK
```

### Errors

An error will be returned if the workitem doesn't belong to the provided
workflow.

If called more than once, an error will be returned saying the workitem can't
be found - this is due to a Ruote limitation.
