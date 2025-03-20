[![FINOS - Incubating](https://cdn.jsdelivr.net/gh/finos/contrib-toolbox@master/images/badge-incubating.svg)](https://finosfoundation.atlassian.net/wiki/display/FINOS/Incubating)
[![Maven Central](https://img.shields.io/maven-central/v/org.finos.legend.depot/legend-depot-server.svg)](https://central.sonatype.com/namespace/org.finos.legend.depot)
![Build CI](https://github.com/finos/legend-depot/workflows/Build%20CI/badge.svg)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=finos_legend-depot&metric=security_rating&token=69394360757d5e1356312ddfee658a6b205e2c97)](https://sonarcloud.io/dashboard?id=legend-depot)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=finos_legend-depot&metric=bugs&token=69394360757d5e1356312ddfee658a6b205e2c97)](https://sonarcloud.io/dashboard?id=legend-depot)


# Legend Depot

Legend Depot provides a rich `REST API` allowing users to query metadata fast and reliably that has been authored in `Legend Studio` and `Legend SDLC`. The Legend Depot servers provide the infrastructure for storing, managing, and accessing metadata artifacts produced by the Legend ecosystem.

## Architecture and Components

Legend Depot consists of two main components that work together to provide a comprehensive metadata management system:

### Depot Server

The Depot Server provides a read-only metadata query REST API that allows users to:
- Query and retrieve metadata entities
- Access entity definitions, properties, and relationships
- Retrieve file generations and transforms
- Get dependency information between projects and entities

The Depot Server is designed for high-performance querying of metadata that has been cached in the underlying MongoDB database by the Depot Store Server.

### Depot Store Server

The Depot Store Server manages the internal metadata cache and sources it from maven-style repositories where model artifacts have been published. Its responsibilities include:
- Registering metadata projects for tracking
- Fetching artifacts from configured Maven repositories
- Caching metadata in MongoDB for fast access
- Managing versions and dependencies between projects
- Handling project configuration and versioning

### Additional Modules

The Legend Depot system is composed of several specialized modules that handle different aspects of metadata management:

- **Core Modules**: Basic functionality for data storage, scheduling, and authorization
- **Artifacts Modules**: Handle artifact retrieval and storage from Maven repositories
- **Entities Modules**: Manage entity metadata and relationships
- **Generations Modules**: Process and store file generations (e.g., JSON Schema, Avro)
- **Notifications Modules**: Handle system notifications and events

### Component Interaction

1. **Metadata Creation and Publishing**:
   - Models are authored in Legend Studio
   - Models are versioned and managed through Legend SDLC
   - Artifacts are published to Maven repositories (e.g., Maven Central, GitLab Packages)

2. **Metadata Ingestion**:
   - Depot Store Server registers projects for tracking
   - Scheduled jobs retrieve artifacts from Maven repositories
   - Metadata is extracted and stored in MongoDB

3. **Metadata Access**:
   - Depot Server provides REST APIs for querying metadata
   - Applications can retrieve metadata reliably and quickly
   - API endpoints provide various query capabilities (by path, entity, version, etc.)

## Prerequisites

Before setting up Legend Depot, ensure you have the following prerequisites installed:

- **Java 11**: Required for running the application
- **Maven 3.6+**: Required for building the application
- **MongoDB**: Required for metadata storage
- **GitLab OAuth** (optional): For authentication if needed

## Setup and Installation

### Building from Source

1. Clone the repository:
   ```sh
   git clone https://github.com/finos/legend-depot.git
   cd legend-depot
   ```

2. Build the project:
   ```sh
   mvn clean install -DskipTests
   ```

3. The build will produce JAR files for both servers in their respective `/target` directories.

### Setting up GitLab OAuth (Optional)

If you need authentication for your Depot Store Server:

1. Follow the instructions [here](https://legend.finos.org/docs/getting-started/installation-guide#maven-install) to set up GitLab authentication
2. Add the following callback URL to your OAuth application configuration: `http://127.0.0.1:6201/depot-store/callback`
3. Add your GitLab handle to `authorisedIdentities.json` for elevated permissions

### Configuring and Starting the Depot Store Server

1. Create a JSON configuration file based on the [sample configuration](https://github.com/finos/legend-depot/blob/master/legend-depot-store-server/src/test/resources/sample-server-config.json)

2. Configure your Maven artifact repository provider:
   - Create a `settings.xml` file for Maven repository access (see [sample settings](https://github.com/finos/legend-depot/blob/master/legend-depot-store-server/src/test/resources/sample-repository-settings.xml))
   - Specify the path to this file in your server configuration under `artifactRepositoryProviderConfiguration`
   - Configure repository URLs, credentials, and local repository location

3. Set up MongoDB:
   - Install and start MongoDB locally (or use a hosted instance)
   - Add the MongoDB URL and database name to the server configuration

4. Start the server:
   ```sh
   java -cp legend-depot-store-server/target/legend-depot-store-server-<version>-shaded.jar org.finos.legend.depot.store.server.LegendDepotStoreServer server path/to/your/config.json
   ```

5. Verify the server is running by accessing:
   - API Info: http://127.0.0.1:6201/depot-store/api/info
   - Swagger UI: http://127.0.0.1:6201/depot-store/api/swagger

### Configuring and Starting the Depot Server

1. Create a JSON configuration file based on the [sample configuration](https://github.com/finos/legend-depot/blob/master/legend-depot-server/src/test/resources/sample-server-config.json)

2. Configure the MongoDB connection to use the same database as the Store Server

3. Start the server:
   ```sh
   java -cp legend-depot-server/target/legend-depot-server-<version>-shaded.jar org.finos.legend.depot.server.LegendDepotServer server path/to/your/config.json
   ```

4. Verify the server is running by accessing:
   - API Info: http://127.0.0.1:6200/depot/api/info
   - Swagger UI: http://127.0.0.1:6200/depot/api/swagger

## Usage and Workflows

### Registering Metadata Projects

Metadata projects must be registered with the Depot Store Server before their artifacts can be cached and queried. This is a one-time setup for each project you want to track.

#### Manual Registration

Use the following REST API endpoint to register a project:

```
PUT http://127.0.0.1:6201/depot-store/api/projects/{projectId}/{groupId}/{artifactId}
```

Where:
- `projectId`: A unique identifier for the project in Legend Depot
- `groupId`: The Maven group ID of the project
- `artifactId`: The Maven artifact ID of the project

Optional query parameters:
- `defaultBranch`: Specifies the default branch to use (defaults to "master" if not specified)
- `latestVersion`: Explicitly sets the latest version (normally determined automatically)

Example using curl:
```sh
curl -X PUT "http://127.0.0.1:6201/depot-store/api/projects/myproject/org.example/model-artifacts"
```

After registration, the Depot Store Server will:
1. Discover available versions from the configured Maven repositories
2. Download artifacts for each version
3. Extract and store metadata in MongoDB
4. Build dependency information

#### Verifying Project Registration

To verify that your project was registered successfully, you can use:

```
GET http://127.0.0.1:6201/depot-store/api/projects
```

This endpoint returns a list of all registered projects.

### Common Workflows

#### Querying Metadata Entities

To retrieve entity definitions for a specific project and version:

```
GET http://127.0.0.1:6200/depot/api/projects/{groupId}/{artifactId}/versions/{version}/entities/packages
```

Example:
```sh
curl -X GET "http://127.0.0.1:6200/depot/api/projects/org.example/model-artifacts/versions/1.0.0/entities/packages"
```

#### Exploring Project Dependencies

To view the dependencies for a specific project version:

```
GET http://127.0.0.1:6200/depot/api/projects/{groupId}/{artifactId}/versions/{version}/dependencies
```

#### Retrieving File Generations

To retrieve file generations (e.g., Avro schemas, JSON schemas) produced by a project:

```
GET http://127.0.0.1:6200/depot/api/projects/{groupId}/{artifactId}/versions/{version}/generations/files
```

#### Finding Project Versions

To list all available versions for a project:

```
GET http://127.0.0.1:6200/depot/api/projects/{groupId}/{artifactId}/versions
```

#### Accessing the Latest Version

To access metadata from the latest version of a project:

```
GET http://127.0.0.1:6200/depot/api/projects/{groupId}/{artifactId}/versions/latest/entities/packages
```

## Pre-populating with Test Data

To pre-populate the Legend Depot servers with test data for use in your legend-studio instance:

1. Start both Depot Server and Depot Store Server
2. Run the seed script:

```bash
cd scripts/seed
./populate-depot.sh
```

This will populate the servers with sample projects and entities. See `scripts/seed/README.md` for more details.

## Troubleshooting

### Maven Repository Connection Issues

If you're having trouble connecting to Maven repositories:
1. Verify your `settings.xml` file is correctly configured
2. Check connection credentials for private repositories
3. Use the API to check repository connection:
   ```
   GET http://127.0.0.1:6201/depot-store/api/artifacts/repository/{groupId}/{artifactId}/versions
   ```

### MongoDB Connection Problems

If the application can't connect to MongoDB:
1. Verify MongoDB is running
2. Check the connection URL in your configuration
3. Ensure the database exists or can be created

## Roadmap

Visit our [roadmap](https://github.com/finos/legend#roadmap) to know more about upcoming features.

## Contributing

Visit Legend [Contribution Guide](https://github.com/finos/legend/blob/master/CONTRIBUTING.md) to learn how to contribute to Legend.

## License

Copyright 2020 Goldman Sachs

Distributed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

SPDX-License-Identifier: [Apache-2.0](https://spdx.org/licenses/Apache-2.0)
