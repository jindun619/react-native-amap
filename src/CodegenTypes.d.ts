// Type declarations for React Native Codegen internal types
// This allows TypeScript to recognize the import but Codegen will use its own types at runtime

declare module 'react-native/Libraries/Types/CodegenTypes' {
  import type { NativeSyntheticEvent } from 'react-native';

  export type BubblingEventHandler<T> = (
    event: NativeSyntheticEvent<T>
  ) => void | Promise<void>;

  export type DirectEventHandler<T> = (
    event: NativeSyntheticEvent<T>
  ) => void | Promise<void>;
}
