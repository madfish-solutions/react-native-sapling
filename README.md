# react-native-sapling

React Native bindings for [airgap-sapling](https://github.com/airgap-it/airgap-sapling) (Zcash Sapling crypto). Compatible with React Native 0.72.x.

All byte arrays are passed and returned as **base64 strings** in JavaScript.

## Installation

```bash
npm install react-native-sapling
# or
yarn add react-native-sapling
```

### Android

The library depends on [airgap-sapling](https://github.com/airgap-it/airgap-sapling) via JitPack. Ensure your root `build.gradle` has:

```groovy
allprojects {
  repositories {
    maven { url 'https://jitpack.io' }
    // ...
  }
}
```

Then link the native module (React Native 0.72 usually auto-links):

```bash
npx react-native link react-native-sapling
```

### iOS

1. Install pods: `cd ios && pod install`
2. **Add the AirGap Sapling Swift package** so the native code can use the Sapling library:
   - In Xcode, open your `.xcworkspace`
   - **File → Add Package Dependencies…**
   - Enter: `https://github.com/airgap-it/airgap-sapling`
   - Add the **Sapling** library to your app target (and ensure it is available to the `RNSapling` / `react_native_sapling` target if needed for linking)

Without this package, the iOS bridge still compiles but will return *"Sapling package not linked"* at runtime.

## Usage

```js
import * as Sapling from 'react-native-sapling';

// All arguments that are byte arrays are base64 strings; numeric values are numbers.

// Init parameters (spend + output params as base64)
await Sapling.initParameters(spendParamsBase64, outputParamsBase64);

// Proving context (create once, reuse for building a transaction)
const contextId = await Sapling.initProvingContext();
try {
  // ... use contextId in prepareOutputDescription, prepareSpendDescriptionWithSpendingKey, createBindingSignature
} finally {
  await Sapling.dropProvingContext(contextId);
}

// Keys (seed and derivation path; seed as base64)
const spendingKey = await Sapling.getExtendedSpendingKey(seedBase64, "m/32'/133'/0'");
const viewingKey = await Sapling.getExtendedFullViewingKey(seedBase64, "m/32'/133'/0'");
// Or from spending key:
const viewingKey2 = await Sapling.getExtendedFullViewingKeyFromSpendingKey(spendingKeyBase64);

// Payment address (viewing key + optional index as base64; omit index for default first address)
const address = await Sapling.getPaymentAddress(viewingKeyBase64, null);
const nextAddress = await Sapling.getNextPaymentAddress(viewingKeyBase64, indexBase64);

// Random scalar
const r = await Sapling.randR();

// … and the rest of the API: getProofAuthorizingKey, verifyCommitment, keyAgreement,
// merkleHash, computeNullifier, prepareOutputDescription, preparePartialOutputDescription,
// getRawPaymentAddress, getDiversifierFromRawPaymentAddress, getPkdFromRawPaymentAddress,
// createBindingSignature, prepareSpendDescriptionWithSpendingKey,
// prepareSpendDescriptionWithAuthorizingKey, signSpendDescription,
// getOutgoingViewingKey, getIncomingViewingKey
```

## API (JS)

All methods return **Promises**. Byte arrays are **base64 strings**; numeric values are **numbers**.

| Method | Notes |
|--------|--------|
| `initParameters(spendParamsBase64, outputParamsBase64)` | Initialize Sapling parameters |
| `initProvingContext()` | Returns `contextId` (number). Call `dropProvingContext(contextId)` when done. |
| `dropProvingContext(contextId)` | Release proving context |
| `getProofAuthorizingKey(spendingKeyBase64)` | |
| `verifyCommitment(commitment, address, value, rcm)` | Returns boolean |
| `keyAgreement(pBase64, skBase64)` | |
| `merkleHash(depth, lhsBase64, rhsBase64)` | |
| `computeNullifier(viewingKey, address, value, rcm, position)` | |
| `prepareOutputDescription(contextId, viewingKey, address, rcm, value)` | |
| `preparePartialOutputDescription(contextId, address, rcm, esk, value)` | |
| `getPaymentAddress(viewingKey, indexBase64 \| null)` | `indexBase64` null = first address |
| `getNextPaymentAddress(viewingKey, indexBase64)` | |
| `getRawPaymentAddress(incomingViewingKey, diversifier)` | |
| `getDiversifierFromRawPaymentAddress(address)` | |
| `getPkdFromRawPaymentAddress(address)` | |
| `randR()` | Random scalar (base64) |
| `createBindingSignature(contextId, balance, sighashBase64)` | |
| `prepareSpendDescriptionWithSpendingKey(contextId, spendingKey, address, rcm, ar, value, anchor, merklePath)` | |
| `prepareSpendDescriptionWithAuthorizingKey(contextId, authorizingKey, address, rcm, ar, value, anchor, merklePath)` | |
| `signSpendDescription(spendDescription, spendingKey, ar, sighash)` | |
| `getExtendedSpendingKey(seedBase64, derivationPath)` | |
| `getExtendedFullViewingKey(seedBase64, derivationPath)` | |
| `getExtendedFullViewingKeyFromSpendingKey(spendingKeyBase64)` | |
| `getOutgoingViewingKey(viewingKeyBase64)` | |
| `getIncomingViewingKey(viewingKeyBase64)` | |

## License

ISC
