export function formatInstallationDisplayName(name) {
  if (!name) return 'NewRelay';

  const trimmed = name.trim();
  if (trimmed.toLowerCase() === 'newrelay') return 'NewRelay';

  return trimmed.charAt(0).toUpperCase() + trimmed.slice(1);
}
