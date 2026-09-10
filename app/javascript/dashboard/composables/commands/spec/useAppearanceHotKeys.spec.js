import { useAppearanceHotKeys } from '../useAppearanceHotKeys';
import { useI18n } from 'vue-i18n';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { setColorTheme } from 'dashboard/helper/themeHelper.js';

vi.mock('vue-i18n');
vi.mock('shared/helpers/localStorage');
vi.mock('dashboard/helper/themeHelper.js');

describe('useAppearanceHotKeys', () => {
  beforeEach(() => {
    useI18n.mockReturnValue({
      t: vi.fn(key => key),
    });

    window.matchMedia = vi.fn().mockReturnValue({ matches: false });
  });

  it('should return goToAppearanceHotKeys computed property', () => {
    const { goToAppearanceHotKeys } = useAppearanceHotKeys();
    expect(goToAppearanceHotKeys.value).toBeDefined();
  });

  it('should have the correct number of appearance options', () => {
    const { goToAppearanceHotKeys } = useAppearanceHotKeys();
    expect(goToAppearanceHotKeys.value.length).toBe(5); // 1 parent + 4 theme options
  });

  it('should have the correct parent option', () => {
    const { goToAppearanceHotKeys } = useAppearanceHotKeys();
    const parentOption = goToAppearanceHotKeys.value.find(
      option => option.id === 'appearance_settings'
    );
    expect(parentOption).toBeDefined();
    expect(parentOption.children.length).toBe(4);
  });

  it('should have the correct theme options', () => {
    const { goToAppearanceHotKeys } = useAppearanceHotKeys();
    const themeOptions = goToAppearanceHotKeys.value.filter(
      option => option.parent === 'appearance_settings'
    );
    expect(themeOptions.length).toBe(4);
    expect(themeOptions.map(option => option.id)).toEqual([
      'light',
      'dark',
      'auto',
      'custom',
    ]);
  });

  it('should call setAppearance when a theme option is selected', () => {
    const { goToAppearanceHotKeys } = useAppearanceHotKeys();
    const lightThemeOption = goToAppearanceHotKeys.value.find(
      option => option.id === 'light'
    );

    lightThemeOption.handler();

    expect(LocalStorage.set).toHaveBeenCalledWith(
      LOCAL_STORAGE_KEYS.COLOR_SCHEME,
      'light'
    );
    expect(setColorTheme).toHaveBeenCalledWith(false);
  });

  it('should handle system dark mode preference', () => {
    window.matchMedia = vi.fn().mockReturnValue({ matches: true });

    const { goToAppearanceHotKeys } = useAppearanceHotKeys();
    const autoThemeOption = goToAppearanceHotKeys.value.find(
      option => option.id === 'auto'
    );

    autoThemeOption.handler();

    expect(LocalStorage.set).toHaveBeenCalledWith(
      LOCAL_STORAGE_KEYS.COLOR_SCHEME,
      'auto'
    );
    expect(setColorTheme).toHaveBeenCalledWith(true);
  });
});
