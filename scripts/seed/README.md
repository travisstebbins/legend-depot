# Legend Depot Seed Script

This script helps populate the Legend Depot servers with sample projects and entities for testing purposes.

## Prerequisites

- Running Legend Depot Store Server (port 6201)
- Running Legend Depot Server (port 6200)
- `jq` command-line tool installed (for JSON processing)
- `curl` command-line tool installed

## Usage

```bash
./populate-depot.sh
```

## Configuration

The script uses test data from the `data/` directory:

- `projects.json`: Contains project definitions
- `versioned-entities.json`: Contains versioned entities
- `revision-entities.json`: Contains revision entities (snapshot versions)

You can customize these files to add your own test data.

## How It Works

1. The script waits for the Depot Store Server to be ready
2. It reads project definitions from projects.json
3. For each project, it:
   - Registers the project in the Depot Store Server
   - Registers the project versions (latest version and master-SNAPSHOT)
   - Uploads entities for each version

## Troubleshooting

If you encounter authentication issues, make sure your Depot Store Server is configured with:

```json
"pac4j": {
  "bypassPaths": [
    "/depot-store/api/info",
    "/depot-store/projects/*/*/",
    "/depot-store/projects/versions/*/*/*"
  ]
}
```
