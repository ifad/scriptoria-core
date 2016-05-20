# Scriptoria Core API Docs - Version 1

## Launch a new workflow

    POST /v1/workflows

To launch a workflow, the full process definition should be sent. Process
definitions are not currently stored in the application.

### Parameters

| Parameter | Mandatory | Description                        |
|-----------|-----------|------------------------------------|
| workflow  | Yes       | Ruote process defintion            |
| callback  | No        | Catch-all callback URL             |
| callbacks | No        | Hash of callback URLs              |
| fields    | No        | Intial hash of the workitem fields |

`workflow` is a [process definition](http://ruote.io/definitions.html) in any
format that Ruote will understand (XML, JSON, Radial).

`callback` is a catch-all callback URL, that will be used for all participants.

`callbacks` is a hash of callback URLs, where the key is the participant name.

Exactly one of `callback` or `callbacks` must be passed - an error will be
returned otherwise.

`fields` is the initial workitem fields. These will be passed on subsequent
callbacks requests.

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
to handle errors, the workitem or entire workflow may be replayed.

If the status is `active` and a callback request fails, it will be retried with
exponential backoff. The final retry will be made after approximately two days,
after which an error will be raised. If the workflow has an `on_error` handler
it will be called, otherwise the workflow will be put into an error state.

### Parameters

| Parameter    | Mandatory | Description                         |
|--------------|-----------|-------------------------------------|
| workflow\_id | Yes       | ID of the workflow                  |
| workitem\_id | Yes       | ID of the workitem                  |
| participant  | Yes       | Participant name                    |
| status       | Yes       | Status of the workitem              |
| fields       | Yes       | Hash of the workitem fields         |
| proceed\_url | Yes       | URL to call to proceed the workitem |

`status` can be `active` (the default), `cancel`, `timeout` or `error`.

### Example Request

```
POST /callbacks/alpha
Content-Type: application/json

{
  "workflow_id":"20151005-1247-kogadeso-gekunute",
  "workitem_id":"0_0!023abf5d398319b1c8fcbfaf70e7c780!20151005-1247-kogadeso-gekunute",
  "participant":"alpha",
  "status":"active",
  "fields":{
    "params":{
      "ref":"alpha"
    }
  },
  "proceed_url":"http://core.dev/v1/workflows/20151005-1247-kogadeso-gekunute/workitems/0_0!023abf5d398319b1c8fcbfaf70e7c780!20151005-1247-kogadeso-gekunute/proceed"
}
```

The application should respond with a 2xx response code in a timely manner. The
intention for this callback is that the application will put a job in a queue
and perform work later, not to actually perform the work during this callback
request. If a 2xx response code is not received or a timeout occurs, the
request will be retried.

## Proceed a workitem

    POST /v1/workflows/:workflow_id/workitems/:workitem_id/proceed

Once a workitem has been completed the proceed action should be called.

### Parameters

| Parameter | Mandatory | Description                              |
|-----------|-----------|------------------------------------------|
| fields    | No        | Hash of fields to be set on the workitem |

`fields` will be merged with existing fields on the workitem. If a field is
already set on the workitem, fields in the `fields` parameter will take
precidence. The fields set here will then be present on subsequent callbacks
requests.

If `fields` is not passed, the proceed action will be called without changing
any fields on the workitem.

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

## Cancel a workflow

    POST /v1/workflows/:workflow_id/cancel

Initiates cancellation of the workflow. All active participants will be called
again with the status `cancel`, and then the workflow will be terminated.

Note that after making this request and receiving a successful response, a
participant callback could still be made with the status `active`, which will
be followed by a callback with the status `cancel`.

### Parameters

| Parameter    | Mandatory | Description        |
|--------------|-----------|--------------------|
| workflow\_id | Yes       | ID of the workflow |

### Example Request

```
curl http://core.dev/v1/workflows/20151005-1247-kogadeso-gekunute/cancel
```

### Example Response

```
HTTP/1.1 201 Accepted
OK
```

### Errors

An error will be returned if the workflow doesn't exist or it has already been
cancelled.
