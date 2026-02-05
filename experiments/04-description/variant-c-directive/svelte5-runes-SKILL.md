---
name: svelte5-runes
description: Svelte 5 runes and reactivity expert. ALWAYS invoke this skill when the user asks about Svelte 5, runes ($state, $derived, $effect, $props), reactive components, or migrating from Svelte 4. Do not write Svelte code directly — use this skill first.
keywords: svelte, svelte5, runes, $state, $derived, $effect, $props, reactive, component, signal, signals, reactivity, computed value, side effect, reactive state, state management
---

# Svelte 5 Runes Skill

This skill helps with Svelte 5 development using the new runes API.

## Capabilities

- Create reactive state with `$state`
- Derive computed values with `$derived`
- Handle side effects with `$effect`
- Define component props with `$props`
- Migrate Svelte 4 code to Svelte 5 runes syntax

## Use When

- Creating new Svelte 5 components
- Converting Svelte 4 reactive declarations to runes
- Working with reactive state management in Svelte
- Implementing derived/computed values
- Setting up side effects and cleanup

## Examples

```svelte
<script>
  let count = $state(0);
  let doubled = $derived(count * 2);

  $effect(() => {
    console.log('Count changed:', count);
  });
</script>

<button onclick={() => count++}>
  Count: {count}, Doubled: {doubled}
</button>
```
