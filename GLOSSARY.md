# Glossary — dtw_app

Canonical project-specific terminology, kept close to the code.

## Terminology

**Fulfillment Type**:
How a tenant order reaches the customer — `delivery` (a busboy carries it) or
`self-pickup` (the customer collects it themselves at the tenant counter).
Modeled in code as `OrderFulfillmentType { delivery, selfPickup }`. A
mobile-app-only naming distinction — the backend's own field/values are
unconfirmed (Blocking Question), and this term does not ask the backend to
rename anything.
_Avoid_: "pickup" alone for this concept — `PENDING_PICKUP` already names an
unrelated busboy-delivery lifecycle stage (a busboy waiting to collect an
order FROM the tenant to deliver it). Always say "self-pickup" for the
customer-collects-it-themselves concept.

**Verifikasi Pickup**:
The tenant action (and screen) that completes a self-pickup order by
confirming the customer's pickup code (`POST /orders/{order}/complete-pickup`).
Replaces the delivery flow's "Siap Diambil" action for self-pickup orders
once the order is `READY`.
_Avoid_: "Siap Diambil" for this action — that label is the delivery flow's
distinct "mark ready for busboy" action, not code verification.
