# Perspective: Spec

Review whether the change conforms to its behavioral spec.

## Spec files — the source of truth

The reference files name the project's specifications. Specs describe intended user
behavior. Treat them as the contract: the change realizes each applicable specified
behavior.

If the change intentionally differs from an outdated or incomplete spec, **propose a
spec update**. State the current and required wording. Do not edit the spec.

## How to review

1. Identify the specs relevant to the change, and read them.
2. Trace typical inputs first. Then trace the edge cases in the spec. Check empty
   collections, zero values, one-element cases, and boundaries. The implementation
   provides each specified behavior without conflict.
3. When tests exist, they exercise specified behavior rather than stubbing it.
4. Check two changes that often leave a spec stale:
   - A feature flag is released or removed. The spec may still call it provisional.
     Propose unconditional wording.
   - User-visible strings change. The spec may quote or paraphrase them.

## Output format note

For each finding, cite the spec file and section. Include an input that triggers the
deviation. Put spec-update suggestions in a separate section:

- **[Spec update suggested — <spec file path>]** State the current text, why the
  change differs, and the replacement text.
