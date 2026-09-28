export function isEnvBrowser(): boolean {
  return !(window as any).invokeNative;
}

export function noop() {}
