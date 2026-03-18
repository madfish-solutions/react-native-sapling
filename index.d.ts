/**
 * React Native bindings for airgap-sapling (Zcash Sapling crypto).
 * Byte arrays are passed and returned as base64 strings.
 */

/** Base64-encoded byte array (string) */
export type Base64 = string;

/** Proving context handle (opaque string; pass to methods that need a context) */
export type ProvingContextId = string;

// Commitment
export function verifyCommitment(
  commitmentBase64: Base64,
  addressBase64: Base64,
  value: number,
  rcmBase64: Base64
): Promise<boolean>;

// Init
export function initParameters(
  spendParametersBase64: Base64,
  outputParametersBase64: Base64
): Promise<void>;

// Merkle Tree
export function merkleHash(
  depth: number,
  lhsBase64: Base64,
  rhsBase64: Base64
): Promise<Base64>;

// Nullifier
export function computeNullifier(
  viewingKeyBase64: Base64,
  addressBase64: Base64,
  value: number,
  rcmBase64: Base64,
  position: number
): Promise<Base64>;

// Output Description
export function prepareOutputDescription(
  contextId: ProvingContextId,
  viewingKeyBase64: Base64,
  addressBase64: Base64,
  rcmBase64: Base64,
  value: number
): Promise<Base64>;

export function preparePartialOutputDescription(
  contextId: ProvingContextId,
  addressBase64: Base64,
  rcmBase64: Base64,
  eskBase64: Base64,
  value: number
): Promise<Base64>;

// Payment Address
export function getPaymentAddress(
  viewingKeyBase64: Base64,
  indexBase64?: Base64 | null
): Promise<Base64>;

export function getNextPaymentAddress(
  viewingKeyBase64: Base64,
  indexBase64: Base64
): Promise<Base64>;

export function getDiversifierFromRawPaymentAddress(addressBase64: Base64): Promise<Base64>;

// Proving Context
export function initProvingContext(): Promise<ProvingContextId>;

export function dropProvingContext(contextId: ProvingContextId): Promise<void>;

// Rand
export function randR(): Promise<Base64>;

// Signature
export function createBindingSignature(
  contextId: ProvingContextId,
  balance: number,
  sighashBase64: Base64
): Promise<Base64>;

// Spend Description
export function prepareSpendDescriptionWithSpendingKey(
  contextId: ProvingContextId,
  spendingKeyBase64: Base64,
  addressBase64: Base64,
  rcmBase64: Base64,
  arBase64: Base64,
  value: number,
  anchorBase64: Base64,
  merklePathBase64: Base64
): Promise<Base64>;

export function signSpendDescription(
  spendDescriptionBase64: Base64,
  spendingKeyBase64: Base64,
  arBase64: Base64,
  sighashBase64: Base64
): Promise<Base64>;

// Spending Key
export function getExtendedSpendingKey(
  seedBase64: Base64,
  derivationPath: string
): Promise<Base64>;

// Viewing Key
export function getExtendedFullViewingKey(
  seedBase64: Base64,
  derivationPath: string
): Promise<Base64>;

export function getExtendedFullViewingKeyFromSpendingKey(
  spendingKeyBase64: Base64
): Promise<Base64>;

export function getIncomingViewingKey(viewingKeyBase64: Base64): Promise<Base64>;

export interface SaplingModule {
  verifyCommitment: typeof verifyCommitment;
  initParameters: typeof initParameters;
  merkleHash: typeof merkleHash;
  computeNullifier: typeof computeNullifier;
  prepareOutputDescription: typeof prepareOutputDescription;
  preparePartialOutputDescription: typeof preparePartialOutputDescription;
  getPaymentAddress: typeof getPaymentAddress;
  getNextPaymentAddress: typeof getNextPaymentAddress;
  getDiversifierFromRawPaymentAddress: typeof getDiversifierFromRawPaymentAddress;
  initProvingContext: typeof initProvingContext;
  dropProvingContext: typeof dropProvingContext;
  randR: typeof randR;
  createBindingSignature: typeof createBindingSignature;
  prepareSpendDescriptionWithSpendingKey: typeof prepareSpendDescriptionWithSpendingKey;
  signSpendDescription: typeof signSpendDescription;
  getExtendedSpendingKey: typeof getExtendedSpendingKey;
  getExtendedFullViewingKey: typeof getExtendedFullViewingKey;
  getExtendedFullViewingKeyFromSpendingKey: typeof getExtendedFullViewingKeyFromSpendingKey;
  getIncomingViewingKey: typeof getIncomingViewingKey;
}

declare const sapling: SaplingModule;
export default sapling;
