# C4 Grill — Question Bank

The question bank for the skill's two-phase Socratic grill. Its job is to **force the
user to engage** with the decisions people always skip when drawing architecture
diagrams: audience, scope boundary, abstraction level, and every relationship. Ask
**one question at a time**, wait for the answer, and always offer a **recommended answer**
so the user can accept a default instead of stalling.

Based on Simon Brown's C4 model (c4model.com).

## Contents

- [Section A — Pre-generation scoping grill](#section-a--pre-generation-scoping-grill)
- [Section B — Interpretation grill (image pasted)](#section-b--interpretation-grill-image-pasted)
- [Section C — Post-generation review grill](#section-c--post-generation-review-grill)

---

## Section A — Pre-generation scoping grill

Run this **before drawing anything**. These questions are hard to skip on purpose —
they pin down what people always leave implicit. Ask them in order, one at a time, each
with a recommended answer.

1. **Audience & decision**
   > "Who is the audience for this diagram, and what decision or conversation should it
   > support? (e.g. onboarding a new engineer, a design review, explaining scope to a
   > non-technical stakeholder.)"
   > *Recommended:* {developers on the team, to build a shared mental model}. The audience
   > sets the abstraction level and how much technology detail belongs on the page.

2. **System in scope (the boundary)**
   > "What is the single software system this diagram is about? Everything inside your
   > boundary is {system}; everything else is a person or an external system."
   > *Recommended:* {the one system your team builds, owns, and can see inside of} —
   > usually one repo / one team boundary. Not a product domain, a business capability,
   > or a team.

3. **People / actors**
   > "Who are the people, roles, or personas that use {system}? Include non-human actors
   > (schedulers, other teams' operators) if they initiate interactions."
   > *Recommended:* {the primary end-user role, plus any admin/operator role}. List each
   > distinct role separately rather than lumping them into "users".

4. **External system dependencies**
   > "What external software systems does {system} depend on, or which depend on it?
   > (auth providers, payment gateways, email/SMS, upstream data feeds, downstream
   > consumers.)"
   > *Recommended:* {name each integration you send data to or receive data from}. If in
   > doubt, include it — omitted external systems are the most common scoping defect.

5. **C4 level(s) to draw now**
   > "Which level are we drawing right now — System Context (the world around {system}),
   > Container (apps and data stores inside it), or Component (inside one container)?
   > We draw one level per diagram."
   > *Recommended:* {start with System Context}, then zoom into Container. Only go to
   > Component for a container that genuinely needs it; skip Code unless auto-generated.

---

## Section B — Interpretation grill (image pasted)

When the user pastes an existing diagram, do **not** silently accept how boxes map to
C4 abstractions. Challenge each mapping before proceeding. The frequent error is
conflating infrastructure with software structure.

- **Per-box abstraction check**
  > "I'm reading the box labelled {name} as a {my-guess: Container}. Is that right — or
  > is it actually a {Component} inside another container, an external {Software System},
  > or a {Deployment Node}?"

- **C4 container vs Docker/K8s container**
  > "The box {name} is labelled 'container'. Do you mean a **C4 container** (a running
  > application or data store), or a **Docker/Kubernetes container** (a deployment
  > artefact)? Those are different concepts and belong on different diagrams."

- **Software vs infrastructure**
  > "{name} looks like infrastructure (a {load balancer / VM / cluster / queue broker}).
  > On a static C4 view we show software systems and containers, not the infra they run
  > on — infra belongs on a Deployment diagram. Should I move {name} there, or does it
  > represent an actual software container?"

- **Boundary check**
  > "Is {name} inside the boundary of {system} (something your team builds and owns), or
  > is it an external system you only integrate with?"

- **Abstraction-level mixing**
  > "This diagram seems to mix levels — {box-A} looks like a whole software system while
  > {box-B} looks like a component inside one container. Which single level should this
  > view be, so we can split the rest out?"

---

## Section C — Post-generation review grill

Run after a diagram is drawn, driven by the review checklist. This phase is
**skippable**: if the user says **"skip the grill"** (or similar), stop and ship the
diagram as-is. Otherwise interrogate each element and relationship.

- **Per-element abstraction justification**
  > "Justify {element}: what abstraction level is it — Person, Software System, Container,
  > Component, or Code — and why? Is it at the same level as everything else here?"

- **Per-element description + technology**
  > "What is {element}'s one-line responsibility, and what technology implements it
  > (e.g. {Java/Spring Boot}, {React}, {PostgreSQL})? Right now it's {missing / bare
  > name}."

- **Unexplained names**
  > "The label {acronym-or-codename} isn't self-explanatory. Spell it out, add a
  > description, or move it to the key — which?"

- **Per-relationship label + direction**
  > "The arrow between {A} and {B} is {unlabelled / labelled 'uses'}. What's the specific
  > intent, and which way does it point? Make it read as a sentence, e.g. '{A} {verb+to}
  > {B}'."

- **Relationship technology**
  > "What protocol/mechanism does {A} to {B} use — {HTTPS, gRPC, JMS, SQL}? And is it
  > synchronous or asynchronous?"

- **Missing external systems**
  > "Does {system} talk to anything not shown here — {auth, payments, email, upstream
  > feeds, downstream consumers}? Missing external systems are the most common omission."

- **Key / legend completeness**
  > "Every colour, shape, icon, border, and line style on this diagram — is each one
  > explained in the key? Anything a reader would have to guess at?"

- **Stand-alone test**
  > "Final check: if I handed this to someone who wasn't here, with no explanation from
  > you, could they read it? If not, what's still missing?"
