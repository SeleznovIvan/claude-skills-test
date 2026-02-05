---
name: svelte5-runes
description: Svelte 5 runes and reactivity expert. Use when working with $state, $derived, $effect, $props runes, creating Svelte 5 components, converting from Svelte 4 to Svelte 5, or any Svelte 5 reactive development task.
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
