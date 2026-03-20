import type { Page } from "@playwright/test";

export interface MockMidiInputConfig {
  id: string;
  name: string;
}

export interface MidiMockOptions {
  /** Whether Web MIDI API is supported. Defaults to true. */
  supported?: boolean;
  /** Available MIDI input devices. Defaults to []. */
  inputs?: MockMidiInputConfig[];
}

/**
 * Set up a Web MIDI API mock before page navigation.
 * Must be called before openPage() / page.goto().
 *
 * Returns a helper that sends mock MIDI messages to a specific input device.
 */
export async function setupMidiMock(
  page: Page,
  options: MidiMockOptions = {},
): Promise<(inputId: string, data: number[]) => Promise<void>> {
  const { supported = true, inputs = [] } = options;

  await page.addInitScript(
    ({ supported, inputs }) => {
      if (!supported) {
        // requestMIDIAccess is defined on Navigator.prototype, so delete on the
        // instance has no effect. Use defineProperty to shadow it with undefined.
        Object.defineProperty(navigator, "requestMIDIAccess", {
          get: () => undefined,
          configurable: true,
        });
        return;
      }

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const mockInputs: any[] = inputs.map(({ id, name }) => ({
        id,
        name,
        type: "input",
        onmidimessage: null as ((event: { data: Uint8Array }) => void) | null,
        open() {
          return Promise.resolve(this);
        },
      }));

      const inputMap = new Map<string, (typeof mockInputs)[0]>(
        mockInputs.map((i) => [i.id, i]),
      );

      const mockAccess = {
        inputs: {
          forEach(cb: (input: unknown, key: string) => void) {
            inputMap.forEach(cb);
          },
        },
        sysexEnabled: false,
      };

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      (navigator as any).requestMIDIAccess = () => Promise.resolve(mockAccess);

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      (window as any).sendMockMIDIMessage = (
        inputId: string,
        data: number[],
      ) => {
        const input = inputMap.get(inputId);
        if (input && input.onmidimessage) {
          input.onmidimessage({ data: new Uint8Array(data) });
        }
      };
    },
    { supported, inputs },
  );

  return async (inputId: string, data: number[]) => {
    await page.evaluate(
      ([id, bytes]) => {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        (window as any).sendMockMIDIMessage(id, bytes);
      },
      [inputId, data] as [string, number[]],
    );
  };
}
