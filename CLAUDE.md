@AGENTS.md

## API rules

- **Never call customer/storefront endpoints** (`/v1/storefront/...`) from this app. They belong to the customer app, are not meant for tenant/busboy tokens (they answer 401), and the shared `dioProvider` treats a 401 as an expired session and logs the user out. If a tenant/busboy screen needs a field only a storefront endpoint exposes, ask the backend to add it to the tenant/busboy endpoint instead of working around it client-side.
