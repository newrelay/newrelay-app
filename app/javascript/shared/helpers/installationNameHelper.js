export function formatInstallationDisplayName(name) {
  if (!name) return 'Newrelay';

  const trimmed = name.trim();
  if (trimmed.toLowerCase() === 'newrelay') return 'Newrelay';

  return trimmed.charAt(0).toUpperCase() + trimmed.slice(1);
}
