# The Archivematica apps

Archivematica is made up of seven different apps. This is a brief summary of those apps, and how they apply to our use case.

*   **dashboard** – the interface to Archivematica. This includes both the graphical component (i.e. the web dashboard) and the Archivematica API.

    It's used by humans to monitor the state of Archivematica transfers, and for machines to manage transfers.
* **storage service** – another term for this might be "storage orchestrator" or "storage adapter". It provides a common interface to various storage backends, e.g. S3, DuraCloud, DSpace, so the rest of Archivematica can interact with various storage backends. This is where we've added code to interact with our storage service.

```mermaid
graph TD
  R[Rest of Archivematica] --> S[<strong>Archivematica<br/>storage service</strong>]
  S --> S3[(Amazon S3)]
  S --> D[(DuraCloud)]
  S --> W[(Wellcome<br/>storage service)]

  classDef externalNode fill:#e8e8e8,stroke:#8f8f8f
  class R,S3,D,W externalNode

  classDef archivematicaNode stroke:#eb6f2e,stroke-width:3px,fill:#f5b694
  class S archivematicaNode
```

*   **MCP services** – these are the tasks that do the actual processing in Archivematica. See [Gearman, ElastiCache and the MCP server/client](gearman-elasticache-and-the-mcp-server-client.md) for more details.

    * MCP Server decides what tasks need to be performed. It uses Gearman and Redis to store persistent information about tasks, to survive e.g. a restart.
    * MCP Client gets tasks from MCP Server (possibly via Gearman), and actually does the work. It may use other containers to help do its work, in particular FITS (for file format identification) and ClamAV (for virus scanning).

    <figure><img src="../../.gitbook/assets/Untitled 2 (1) (1).png" alt=""><figcaption></figcaption></figure>

```mermaid
graph LR
  S[MCP Server] --> G[Gearman]
  G --> R[("Redis (ElastiCache)")]
  S --> C[MCP Client]
  C --> F["FITS (format<br/>identification)"]
  C --> Cl["ClamAV (virus scanning)"]

  classDef externalNode fill:#e8e8e8,stroke:#8f8f8f
  class S,G,R,C,F,Cl externalNode

```
