/**
 * React Native bindings for airgap-sapling (Zcash Sapling crypto).
 * Byte arrays are passed and returned as base64 strings.
 */

import { NativeModules } from 'react-native'

const { RNSapling } = NativeModules

if (!RNSapling) {
  throw new Error('react-native-sapling: Native module RNSapling is not linked.')
}

function promisify(name, fn) {
  return (...args) =>
    new Promise((resolve, reject) => {
      fn(...args, (err, result) => {
        if (err == null) resolve(result)
        else reject(err instanceof Error ? err : new Error(String(err)))
      })
    })
}

// Commitment
export const verifyCommitment = promisify('verifyCommitment', RNSapling.verifyCommitment)

// Init
export const initParameters = promisify('initParameters', RNSapling.initParameters)

// Merkle Tree
export const merkleHash = promisify('merkleHash', RNSapling.merkleHash)

// Nullifier
export const computeNullifier = promisify('computeNullifier', RNSapling.computeNullifier)

// Output Description
export const prepareOutputDescription = promisify('prepareOutputDescription', RNSapling.prepareOutputDescription)
export const preparePartialOutputDescription = promisify(
  'preparePartialOutputDescription',
  RNSapling.preparePartialOutputDescription
)

// Payment Address
export const getPaymentAddress = promisify('getPaymentAddress', RNSapling.getPaymentAddress)
export const getNextPaymentAddress = promisify('getNextPaymentAddress', RNSapling.getNextPaymentAddress)
export const getDiversifierFromRawPaymentAddress = promisify(
  'getDiversifierFromRawPaymentAddress',
  RNSapling.getDiversifierFromRawPaymentAddress
)

// Proving Context (contextId is a string; store and pass to other methods)
export const initProvingContext = promisify('initProvingContext', RNSapling.initProvingContext)
export const dropProvingContext = promisify('dropProvingContext', RNSapling.dropProvingContext)

// Rand
export const randR = promisify('randR', RNSapling.randR)

// Signature
export const createBindingSignature = promisify('createBindingSignature', RNSapling.createBindingSignature)

// Spend Description
export const prepareSpendDescriptionWithSpendingKey = promisify(
  'prepareSpendDescriptionWithSpendingKey',
  RNSapling.prepareSpendDescriptionWithSpendingKey
)
export const signSpendDescription = promisify('signSpendDescription', RNSapling.signSpendDescription)

// Spending Key
export const getExtendedSpendingKey = promisify('getExtendedSpendingKey', RNSapling.getExtendedSpendingKey)

// Viewing Key
export const getExtendedFullViewingKey = promisify(
  'getExtendedFullViewingKey',
  RNSapling.getExtendedFullViewingKey
)
export const getExtendedFullViewingKeyFromSpendingKey = promisify(
  'getExtendedFullViewingKeyFromSpendingKey',
  RNSapling.getExtendedFullViewingKeyFromSpendingKey
)
export const getIncomingViewingKey = promisify('getIncomingViewingKey', RNSapling.getIncomingViewingKey)

export default {
  verifyCommitment,
  initParameters,
  merkleHash,
  computeNullifier,
  prepareOutputDescription,
  preparePartialOutputDescription,
  getPaymentAddress,
  getNextPaymentAddress,
  getDiversifierFromRawPaymentAddress,
  initProvingContext,
  dropProvingContext,
  randR,
  createBindingSignature,
  prepareSpendDescriptionWithSpendingKey,
  signSpendDescription,
  getExtendedSpendingKey,
  getExtendedFullViewingKey,
  getExtendedFullViewingKeyFromSpendingKey,
  getIncomingViewingKey,
}
