# Copilot Context Engineering Repository Constitution

<!--
Sync Impact Report:
Version: 1.0.0 → 1.1.0
Rationale: MINOR — added VS Code extension as a deliverable category
  and expanded repository scope descriptions to reflect actual usage
  as a personal toolkit (not purely educational).

Modified Principles:
  - I. Documentation-First — rationale updated to acknowledge code
    and tooling as co-equal deliverables alongside documentation
  - III. Evidence-Based Recommendations — no structural change;
    scope note clarified to apply to educational content specifically

Added Sections:
  - Deliverable category 5 (VS Code Extension) under Output Standards

Removed Sections: None

Templates Status:
  ✅ plan-template.md - Reviewed, no changes needed
  ✅ spec-template.md - Reviewed, aligned with documentation-first principle
  ✅ tasks-template.md - Reviewed, aligned with iterative development principle
  ✅ agent-file-template.md - Reviewed (not in templates/commands)
  ✅ checklist-template.md - Reviewed, no changes needed

Follow-up TODOs: None
-->

## Core Principles

### I. Documentation-First (NON-NEGOTIABLE)

All research findings, recommendations, and educational materials MUST be
captured as markdown documents before any supporting code or tooling is
created. For features that include code (scripts, extensions), a spec or
design document MUST exist before implementation begins.

**Rationale**: This repository serves as both a personal toolkit and a
reference collection for context engineering. Documentation ensures
decisions are traceable, shareable, and reviewable. Writing the design
down first prevents wasted implementation effort and keeps the
repository useful as a teaching example.

### II. Mermaid Diagrams for Visual Communication

Complex context engineering concepts, workflows, and relationships MUST
be illustrated using Mermaid diagrams embedded in markdown. Text-only
explanations are insufficient for architectural and process
documentation.

**Rationale**: Context engineering involves complex relationships between
specifications, code, instructions, agents, and skills. Visual
representations accelerate understanding and serve as quick-reference
guides. Mermaid ensures diagrams remain version-controlled and editable
as text.

### III. Evidence-Based Recommendations

Every recommendation about context engineering practices MUST be
supported by:

- Concrete examples from real repositories
- Links to authoritative sources (GitHub documentation, whitepapers,
  research)
- Before/after comparisons demonstrating effectiveness
- Measurable outcomes when applicable

**Rationale**: Educational and reference content in this repository
teaches best practices. Unsupported opinions undermine credibility.
Practitioners need evidence to justify adoption of context engineering
techniques in their organizations.

### IV. Practical, Actionable Guidance

All materials MUST provide step-by-step implementation instructions.
Conceptual explanations without "how-to" sections are incomplete.

**Rationale**: The target audience wants to implement context
engineering, not just understand it theoretically. Each document must
answer "How do I actually do this in my repository?"

### V. Spec Kit as Living Example

This repository uses Spec Kit itself to demonstrate context engineering
principles. The `.specify/` directory structure, templates, prompts, and
this constitution serve as working examples.

**Rationale**: "Show, don't just tell." Users can examine this
repository's own Spec Kit configuration to see principles in action.
The repository dogfoods its own recommendations.

### VI. Iterative Development Over Perfection

Documents, scripts, and extensions are released incrementally. It is
better to ship a focused, well-tested increment than to delay for
comprehensive coverage.

**Rationale**: Context engineering practices evolve as GitHub Copilot
capabilities expand. Iterative releases allow faster feedback and
course correction. Perfection is the enemy of progress.

## Output Standards

### Deliverable Categories

This repository produces five categories of deliverables:

1. **Educational Materials**: Guides explaining what context engineering
   is, why it matters, and how to implement it
2. **Template Repositories**: Reference implementations and starter
   templates others can clone
3. **Analysis & Research**: Case studies and empirical analysis of
   context engineering effectiveness
4. **Scripts**: Shell scripts that integrate with the Copilot CLI for
   commit generation, PR creation, and other workflow automation
5. **VS Code Extension**: A privately used VS Code extension for
   personal workflow automation. This extension is NOT published to any
   marketplace; it is side-loaded for private use only

### Quality Gates

Before merging content:

- [ ] **Clarity**: Can a developer unfamiliar with context engineering
  understand it?
- [ ] **Completeness**: Does it include examples, diagrams, and links
  to further reading?
- [ ] **Accuracy**: Are all claims about GitHub Copilot capabilities
  verified against official documentation?
- [ ] **Actionability**: Can someone follow the steps and achieve the
  described outcome?

### Mandatory Sections for Educational Documents

- **Overview**: What concept is being taught
- **Why It Matters**: Business/technical value proposition
- **How to Implement**: Step-by-step instructions with file paths and
  code examples
- **Visual Diagram**: Mermaid or other embedded visualization
- **Examples**: Link to real repositories or inline demonstrations
- **Further Reading**: Citations and related resources

## Spec Kit Configuration

### Git Operations Disabled

Spec Kit commands in this repository MUST NOT perform git operations.
Specifically:

- `speckit.specify` MUST NOT create feature branches
- `speckit.specify` MUST NOT validate current branch before execution
- `speckit.plan` MUST NOT create or switch branches
- No Spec Kit commands should require working from a feature branch

**Rationale**: This repository uses a documentation-first workflow.
Spec Kit commands produce markdown artifacts and MUST NOT make
assumptions about branching strategy. The shell scripts in `scripts/`
handle git operations independently.

### Output Format

All Spec Kit commands MUST produce markdown documents as outputs. No
compiled artifacts, no binary files, no non-text formats except
embedded images/diagrams within markdown.

**Rationale**: Ensures all outputs remain version-controllable,
diff-able, and accessible without specialized tools.

## Governance

### Amendment Process

1. Propose constitution changes via pull request
2. Update this document with rationale for changes
3. Increment version number according to semantic versioning (see
   below)
4. Update affected templates, commands, and documentation (tracked in
   Sync Impact Report comment)
5. Merge only after review confirms no contradictions with existing
   principles

### Versioning Policy

**Format**: MAJOR.MINOR.PATCH

- **MAJOR**: Removal or fundamental redefinition of a core principle
- **MINOR**: Addition of new principles or sections
- **PATCH**: Clarifications, wording improvements, typo fixes

### Compliance Reviews

Project maintainers MUST review pull requests for constitutional
compliance:

- Do documentation PRs follow the documentation-first principle?
- Do recommendations provide evidence and examples?
- Are Mermaid diagrams included for complex workflows?
- Does any Spec Kit command avoid git operations as required?

Violations MUST be addressed before merge or justified with amendment
proposal.

### Living Document Philosophy

This constitution evolves with the repository. As context engineering
practices mature and GitHub Copilot capabilities expand, principles may
be refined. The goal is usefulness, not rigidity.

**Version**: 1.1.0 | **Ratified**: 2026-01-18 | **Last Amended**: 2026-02-14
