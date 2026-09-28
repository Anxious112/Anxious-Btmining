import { getMockResponse } from '../data/mockData';
import { isEnvBrowser } from './misc';

export async function fetchNui<T = unknown>(eventName: string, data?: unknown, mockData?: T): Promise<T> {
  const options = {
    method: 'post',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  };

  if (isEnvBrowser()) {
    const autoMock = getMockResponse<T>(eventName, data);
    if (autoMock !== undefined) return autoMock;
    if (mockData !== undefined) return mockData;
  }

  const resourceName = (window as any).GetParentResourceName ? (window as any).GetParentResourceName() : 'anxious_btcmining';

  const resp = await fetch(`https://${resourceName}/${eventName}`, options);
  return resp.json();
}
