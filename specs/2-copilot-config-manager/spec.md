# Feature Specification: Copilot Config Manager

**Spec Directory**: `specs/2-copilot-config-manager`  
**Created**: January 22, 2026  
**Status**: Draft  
**Input**: User description: "i want to create a spec that describes tooling for managing github copilot configurations. for example, i want to be able to use it to create copilot instructions files, copilot agent files, etc. I also want it to scan my repo and compare my implementation with recommendations from github copilot documentation, so that my repo stays up to date with the most recent guidance."

## User Scenarios & Testing

### User Story 1 - Create Copilot Instructions File (Priority: P1)

As a developer, I want to create a new GitHub Copilot instructions file from a guided workflow so that I can quickly configure Copilot behavior for my repository without needing to remember the correct file format and location.

**Why this priority**: Instructions files are the foundational configuration for Copilot. Without this capability, developers must manually create files and look up syntax, which is error-prone and time-consuming.

**Independent Test**: Can be fully tested by running the create command and verifying a valid instructions file is created at the correct location with proper structure.

**Acceptance Scenarios**:

1. **Given** I am in a repository without Copilot instructions, **When** I run the create instructions command, **Then** a properly structured instructions file is created in the `.github/instructions/` directory
2. **Given** I specify a technology (e.g., Python, TypeScript), **When** I run the create instructions command, **Then** a technology-specific instructions file is created (e.g., `.github/instructions/python.instructions.md`)
3. **Given** I am in a repository with an existing instructions file for a technology, **When** I run the create instructions command for the same technology, **Then** I am prompted to confirm before overwriting
4. **Given** I run the create command with content options, **When** the command completes, **Then** the generated file includes the specified content sections
5. **Given** I want to see examples before creating, **When** I request examples, **Then** I can browse real-world instructions from community repositories

---

### User Story 2 - Create Copilot Agent Configuration (Priority: P1)

As a developer, I want to create Copilot agent configuration files so that I can define custom agents with specific capabilities for my project.

**Why this priority**: Agent configuration is equally critical to instructions files for projects that need specialized Copilot behaviors or custom agent definitions.

**Independent Test**: Can be fully tested by running the create agent command and verifying a valid agent configuration is created with proper YAML/JSON structure.

**Acceptance Scenarios**:

1. **Given** I am in a repository, **When** I run the create agent command, **Then** a properly structured agent configuration file is created at the appropriate location
2. **Given** I provide agent name and description, **When** the agent file is created, **Then** it contains the specified metadata and default configuration structure
3. **Given** I create multiple agents, **When** I list agents, **Then** all created agents are discoverable
4. **Given** I want to see examples before creating, **When** I request examples, **Then** I can browse real-world agent configurations from community repositories

---

### User Story 3 - Create Copilot Skills (Priority: P1)

As a developer, I want to create Copilot skill definitions so that I can extend agent capabilities with reusable, specialized functions for my project.

**Why this priority**: Skills are essential building blocks that enhance agent functionality. Creating skills enables teams to build specialized capabilities that can be shared across multiple agents.

**Independent Test**: Can be fully tested by running the create skill command and verifying a valid skill definition is created with proper structure and can be attached to agents.

**Acceptance Scenarios**:

1. **Given** I am in a repository, **When** I run the create skill command, **Then** a properly structured skill definition file is created at the appropriate location
2. **Given** I provide skill name, description, and capability type, **When** the skill file is created, **Then** it contains the specified metadata and configuration structure
3. **Given** I have created a skill, **When** I list available skills, **Then** the new skill appears in the list
4. **Given** I have a skill definition, **When** I attach it to an agent configuration, **Then** the agent recognizes and can use the skill
5. **Given** I want to see examples before creating, **When** I request examples, **Then** I can browse real-world skill definitions from community repositories

---

### User Story 4 - Analyze Repository Technologies and Recommend Configurations (Priority: P1)

As a developer, I want the tool to scan my repository for existing technologies (languages, frameworks, libraries) and recommend which Copilot agents, instructions files, and skills I should create so that my Copilot configuration is tailored to my specific project.

**Why this priority**: Technology-aware recommendations ensure users create relevant configurations from the start, rather than generic ones. This maximizes Copilot's effectiveness for the specific codebase.

**Independent Test**: Can be fully tested by running the analyze command on a repository and receiving technology-specific recommendations for Copilot configurations.

**Acceptance Scenarios**:

1. **Given** I have a repository with Python and FastAPI, **When** I run the analyze command, **Then** I receive recommendations for Python-specific instructions and API-focused agent configurations
2. **Given** I have a repository with multiple languages and frameworks, **When** I run the analyze command, **Then** recommendations cover all detected technologies with prioritization
3. **Given** I have a repository with detected technologies, **When** I view recommendations, **Then** each recommendation explains why it's relevant to my specific tech stack
4. **Given** I accept a recommendation, **When** I choose to create the suggested configuration, **Then** the configuration is pre-populated with technology-specific content

---

### User Story 5 - Browse Examples from Community Repositories (Priority: P2)

As a developer, I want to browse examples of Copilot instructions, agents, and skills from curated community repositories so that I can learn from real-world implementations and use them as templates for my own configurations.

**Why this priority**: Learning from examples accelerates adoption and improves configuration quality. Access to curated examples from trusted sources reduces the learning curve.

**Independent Test**: Can be fully tested by running the browse examples command and receiving a list of categorized examples from external repositories.

**Acceptance Scenarios**:

1. **Given** I want to see example configurations, **When** I run the browse examples command, **Then** I see a categorized list of examples from github/awesome-copilot and microsoft/hve-core repositories
2. **Given** I am browsing examples, **When** I select an example, **Then** I can view its full content and metadata
3. **Given** I find a relevant example, **When** I choose to use it as a template, **Then** a new configuration is created in my repository based on that example
4. **Given** I am browsing examples, **When** I filter by configuration type (instructions, agents, skills), **Then** only examples of that type are shown
5. **Given** the external repositories are unavailable, **When** I try to browse examples, **Then** I receive a clear error message and can still create configurations manually

---

### User Story 6 - Scan Repository for Copilot Configuration (Priority: P2)

As a developer, I want to scan my repository to discover existing Copilot configuration files so that I understand what configurations are currently in place.

**Why this priority**: Before making changes or comparing with recommendations, users need to understand their current state. This enables the compliance checking feature.

**Independent Test**: Can be fully tested by running the scan command on a repository and receiving a report of all Copilot-related configuration files found.

**Acceptance Scenarios**:

1. **Given** I have a repository with Copilot configuration files, **When** I run the scan command, **Then** all Copilot configuration files are listed with their locations
2. **Given** I have a repository without any Copilot configuration, **When** I run the scan command, **Then** I receive a clear message indicating no configurations were found
3. **Given** I have partial configuration, **When** I run the scan command, **Then** the report indicates which configuration types are present and which are missing

---

### User Story 7 - Compare Configuration with GitHub Recommendations (Priority: P2)

As a developer, I want to compare my repository's Copilot configuration against the latest GitHub Copilot documentation recommendations so that I can identify gaps and ensure I'm following best practices.

**Why this priority**: This is the key differentiator that helps developers stay current with evolving Copilot guidance without manually tracking documentation changes.

**Independent Test**: Can be fully tested by running the compare command and receiving a report showing alignment or gaps with current recommendations.

**Acceptance Scenarios**:

1. **Given** my repository has Copilot configuration, **When** I run the compare command, **Then** I receive a report comparing my configuration against current GitHub recommendations
2. **Given** my configuration is missing recommended elements, **When** the comparison completes, **Then** the report clearly identifies what is missing and provides guidance on how to add it
3. **Given** my configuration follows all recommendations, **When** the comparison completes, **Then** I receive confirmation that my configuration is up to date

---

### User Story 8 - Update Configuration to Match Recommendations (Priority: P3)

As a developer, I want to automatically update my Copilot configuration to match GitHub recommendations so that I can quickly bring my repository into compliance without manual editing.

**Why this priority**: While valuable, this depends on the scan and compare features. Automatic updates also carry risk and should be used after understanding the gaps.

**Independent Test**: Can be fully tested by running the update command and verifying configuration files are modified to include recommended content.

**Acceptance Scenarios**:

1. **Given** my configuration has identified gaps, **When** I run the update command, **Then** I am shown a preview of proposed changes before they are applied
2. **Given** I approve the proposed changes, **When** the update completes, **Then** my configuration files are modified to include the recommended content
3. **Given** I decline the proposed changes, **When** I cancel, **Then** no modifications are made to my files

---

### Edge Cases

- What happens when the repository has non-standard Copilot configuration file locations?
- How does the system handle corrupted or invalid configuration files?
- What happens when GitHub documentation is unreachable during comparison?
- How does the system handle conflicting recommendations (e.g., project-specific needs vs. general guidance)?
- What happens when running commands in a repository without git initialized?
- What happens when the repository uses technologies the tool doesn't recognize?
- How does the system handle monorepos with multiple distinct technology stacks?

## Requirements

### Functional Requirements

- **FR-001**: System MUST discover all Copilot configuration files in a repository (instructions, agents, prompts)
- **FR-002**: System MUST detect programming languages, frameworks, and libraries used in the repository
- **FR-003**: System MUST recommend appropriate Copilot configurations based on detected technologies
- **FR-004**: System MUST provide technology-specific content templates for recommended configurations
- **FR-005**: System MUST create properly structured Copilot instructions files in the `.github/instructions/` directory, with one file per technology (e.g., `python.instructions.md`, `typescript.instructions.md`)
- **FR-006**: System MUST create properly structured Copilot agent configuration files
- **FR-007**: System MUST create properly structured Copilot skill definitions
- **FR-008**: System MUST support attaching skills to agent configurations
- **FR-009**: System MUST validate configuration file syntax before creating or updating
- **FR-010**: System MUST prompt for confirmation before overwriting existing files
- **FR-011**: System MUST fetch current GitHub Copilot documentation recommendations for comparison
- **FR-012**: System MUST generate a comparison report showing alignment with recommendations
- **FR-013**: System MUST identify missing, outdated, or non-compliant configuration elements
- **FR-014**: System MUST provide actionable guidance for each identified gap
- **FR-015**: System MUST preview proposed changes before applying updates
- **FR-016**: System MUST preserve user customizations when updating configurations
- **FR-017**: System MUST support the following Copilot configuration types: instructions files, agent configurations, prompt files, and skills
- **FR-018**: System MUST fetch and display example configurations from github/awesome-copilot repository
- **FR-019**: System MUST fetch and display example configurations from microsoft/hve-core repository
- **FR-020**: System MUST allow users to use fetched examples as templates for new configurations
- **FR-021**: System MUST categorize examples by configuration type (instructions, agents, skills)
- **FR-022**: System MUST gracefully handle unavailability of external example repositories

### Key Entities

- **Repository Configuration**: Represents the collection of all Copilot configuration files in a repository, including their locations and content
- **Instructions File**: A markdown file that provides behavioral guidance to Copilot for a specific technology, located in `.github/instructions/` (e.g., `.github/instructions/python.instructions.md`)
- **Agent Configuration**: A configuration file defining a custom Copilot agent with specific capabilities and behaviors
- **Prompt File**: A reusable prompt template that can be referenced in Copilot interactions
- **Recommendation Set**: A collection of best practices and guidance from GitHub Copilot documentation
- **Compliance Report**: A comparison result showing how repository configuration aligns with recommendations
- **Technology Profile**: A detected set of languages, frameworks, and libraries present in the repository
- **Configuration Recommendation**: A suggested Copilot configuration (agent, instructions, skill) tailored to detected technologies
- **Skill Definition**: A reusable capability that can be attached to agents to extend their functionality
- **Example Repository**: A curated external repository (github/awesome-copilot, microsoft/hve-core) containing reference implementations of Copilot configurations

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can create a new Copilot instructions file in under 1 minute
- **SC-002**: Users can analyze a repository and receive technology-based recommendations in under 1 minute
- **SC-003**: Users can scan a repository and receive a configuration report in under 30 seconds
- **SC-004**: Users can compare their configuration against recommendations and understand gaps in under 2 minutes
- **SC-005**: 90% of users successfully create valid configuration files on first attempt
- **SC-006**: Configuration files created by the tool pass GitHub's Copilot configuration validation
- **SC-007**: Users spend 50% less time maintaining Copilot configurations compared to manual management
- **SC-008**: Users can identify and remediate configuration gaps within 5 minutes of running a comparison
- **SC-009**: Technology-based recommendations match the actual tech stack in 95% of cases

## Assumptions

- GitHub maintains publicly accessible documentation for Copilot configuration best practices
- The tool will be used primarily in Git repositories
- Users have appropriate permissions to create and modify files in the repository's `.github` directory
- Copilot configuration formats (markdown for instructions, YAML/JSON for agents) remain stable
- The tool will handle rate limiting gracefully when fetching external documentation
- The github/awesome-copilot repository remains publicly accessible and contains curated Copilot examples
- The microsoft/hve-core repository remains publicly accessible and contains reference implementations
- External repository structure and example formats remain stable or the tool can adapt to changes
