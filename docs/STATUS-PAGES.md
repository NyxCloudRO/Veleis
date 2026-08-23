# Status Pages

[← Documentation home](../README.md) · [Security](SECURITY.md) · [Operability hardening](OPERABILITY-HARDENING.md)

Status Pages publish a deliberately selected, privacy-safe view of monitoring
health and incident communication. A page remains private until explicitly
published; an unpublished public slug returns 404.

## Create and publish

Create or select a page in the authenticated Status Pages workspace. The compact
header shows its name, explicit **Published** or **Unpublished** state, copyable
public path, and direct **Publish** or **Unpublish** action. **View public page**
appears only while published. The configuration revision remains available as
secondary concurrency context instead of competing with the page identity.
Internal names and source details remain authenticated-only.

## Workspace

- **Overview** shows publication state, public URL, complete enabled/disabled
  and health aggregates, and active public incident counts without loading the
  component collection.
- **Components** provides Add Component at the top, compact rows, server search,
  status/type/enabled filters, configured-order/name/status sorting, and
  25/50/100-page pagination.
- **Incidents** separates the linked-incident publish flow, active public
  incidents, and bounded history from component administration.
- **Settings** contains page-level identity and publication configuration.

Overview, Components, Incidents, and Settings remain on the active tab after a
save or server refresh. Selecting a different page is deliberate and does not
depend on whichever page happened to arrive first in a request.

Editing opens a bounded editor for public name, public description, private
source context, enabled state, and order. Move-to-position supports large lists
without hundreds of Move Up clicks. Revision checks reject stale concurrent
writes. Enable, disable, and explicitly confirmed remove operations support at
most 100 selected components per request and remain subject to server RBAC.

Component groups were evaluated for 1.8.0 and intentionally deferred. Adding
group identity, two-dimensional ordering, migration, and another public
projection would have enlarged upgrade and privacy risk without being required
to remove the 1,000-row bottleneck; no partial group model is shipped.

## Incidents

Publishing an incident links an existing real incident while storing operator-
written public title and copy. Resolving or removing the public presentation
does not mutate the real incident. Public updates and history are bounded and
contain only the explicit public presentation.

Empty component, incident, and incident-update collections are always JSON
arrays (`[]`), never `null`. Administration and public clients also normalize a
transient legacy null collection at the data boundary without turning request
failures into empty success. This keeps newly created/empty pages,
remove-last-item flows, rapid tab changes, refresh-after-save, search and
pagination edges, and upgraded 1.8.0 pages stable.

## Public behavior and privacy

Aggregate health is computed over every enabled component, not merely the
visible page. Component and incident responses are paginated so a 1,000-item
page does not create an unbounded response or DOM. The public UI uses compact,
responsive rows and contains no administration controls.

Public HTML, JSON, hydration, and network responses omit probe targets, probe
and asset IDs, provider IDs, internal names/labels/metadata, credentials,
tokens, and private incident details. An internal hostname or address appears
only if an operator deliberately types it into a public name or description.

For a large page, use specific public names, server search/filters, 25–100 row
pages, move-to-position, and bounded bulk actions. If a public aggregate looks
wrong, check disabled components and source health in the authenticated
workspace; never expose a private probe target to troubleshoot a public view.
