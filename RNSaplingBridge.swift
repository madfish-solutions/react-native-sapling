//
//  RNSaplingBridge.swift
//  react-native-sapling
//
//  Bridges RNSapling Obj-C module to the Sapling Swift wrapper (Sapling.swift),
//  which in turn calls into SaplingFFI (vendored xcframework).
//

import Foundation

public typealias RNSaplingStringCompletion = (String?, String?) -> Void
public typealias RNSaplingContextCompletion = (NSNumber?, String?) -> Void

@objc(RNSaplingBridge)
public class RNSaplingBridge: NSObject {

  private static let sapling = Sapling()
  private static var contextStore: [Int: Sapling.Context] = [:]
  private static var nextContextId = 0
  private static let lock = NSLock()

  private static func data(fromBase64 b64: String?) -> [UInt8]? {
    guard let b64 = b64, !b64.isEmpty, let data = Data(base64Encoded: b64) else { return nil }
    return [UInt8](data)
  }

  private static func base64(from bytes: [UInt8]) -> String {
    Data(bytes).base64EncodedString()
  }

  private static func result(_ bytes: [UInt8]) -> String? { base64(from: bytes) }
  private static func result(_ value: Bool) -> String? { value ? "1" : "0" }

  // MARK: - Commitment

  @objc(verifyCommitment:addressB64:value:rcmB64:completion:)
  public static func verifyCommitment(
    _ commitmentB64: String?,
    addressB64: String?,
    value: NSNumber?,
    rcmB64: String?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = verifyCommitmentImpl(commitmentB64, addressB64, value, rcmB64)
    completion(r.0, r.1)
  }

  private static func verifyCommitmentImpl(_ commitmentB64: String?, _ addressB64: String?, _ value: NSNumber?, _ rcmB64: String?) -> (String?, String?) {
    guard let commitment = data(fromBase64: commitmentB64),
          let address = data(fromBase64: addressB64),
          let rcm = data(fromBase64: rcmB64),
          let v = value?.uint64Value else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.verifyCommitment(commitment, to: address, forValue: v, with: rcm)), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  // MARK: - Init

  @objc(initParameters:outputB64:completion:)
  public static func initParameters(
    _ spendB64: String?,
    outputB64: String?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = initParametersImpl(spendB64, outputB64)
    completion(r.0, r.1)
  }

  private static func initParametersImpl(_ spendB64: String?, _ outputB64: String?) -> (String?, String?) {
    guard let spend = data(fromBase64: spendB64), let output = data(fromBase64: outputB64) else { return (nil, "Invalid args") }
    do {
      try sapling.initParameters(spend: spend, output: output)
      return ("", nil)
    } catch { return (nil, error.localizedDescription) }
  }

  // MARK: - Key Agreement

  // TODO: Add keyAgreement when it is fixed for Android

  // MARK: - Merkle Tree

  @objc(merkleHash:lhsB64:rhsB64:completion:)
  public static func merkleHash(
    _ depth: NSNumber?,
    lhsB64: String?,
    rhsB64: String?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = merkleHashImpl(depth, lhsB64, rhsB64)
    completion(r.0, r.1)
  }

  private static func merkleHashImpl(_ depth: NSNumber?, _ lhsB64: String?, _ rhsB64: String?) -> (String?, String?) {
    guard let lhs = data(fromBase64: lhsB64), let rhs = data(fromBase64: rhsB64), let d = depth?.intValue else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.merkleHash(ofDepth: d, lhs: lhs, rhs: rhs)), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  // MARK: - Nullifier

  @objc(computeNullifier:addressB64:value:rcmB64:position:completion:)
  public static func computeNullifier(
    _ viewingKeyB64: String?,
    addressB64: String?,
    value: NSNumber?,
    rcmB64: String?,
    position: NSNumber?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = computeNullifierImpl(viewingKeyB64, addressB64, value, rcmB64, position)
    completion(r.0, r.1)
  }

  private static func computeNullifierImpl(_ viewingKeyB64: String?, _ addressB64: String?, _ value: NSNumber?, _ rcmB64: String?, _ position: NSNumber?) -> (String?, String?) {
    guard let vk = data(fromBase64: viewingKeyB64), let address = data(fromBase64: addressB64),
          let rcm = data(fromBase64: rcmB64), let v = value?.uint64Value, let pos = position?.uint64Value else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.computeNullifier(using: vk, to: address, forValue: v, with: rcm, at: pos)), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  // MARK: - Output Description

  @objc(prepareOutputDescription:viewingKeyB64:addressB64:rcmB64:value:completion:)
  public static func prepareOutputDescription(
    _ contextId: NSNumber?,
    viewingKeyB64: String?,
    addressB64: String?,
    rcmB64: String?,
    value: NSNumber?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = prepareOutputDescriptionImpl(contextId, viewingKeyB64, addressB64, rcmB64, value)
    completion(r.0, r.1)
  }

  private static func prepareOutputDescriptionImpl(_ contextId: NSNumber?, _ viewingKeyB64: String?, _ addressB64: String?, _ rcmB64: String?, _ value: NSNumber?) -> (String?, String?) {
    guard let cid = contextId?.intValue, let ctx = contextStore[cid],
          let vk = data(fromBase64: viewingKeyB64), let address = data(fromBase64: addressB64),
          let rcm = data(fromBase64: rcmB64), let v = value?.uint64Value else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.prepareOutputDescription(with: ctx, using: vk, to: address, withRcm: rcm, ofValue: v)), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  @objc(preparePartialOutputDescription:addressB64:rcmB64:eskB64:value:completion:)
  public static func preparePartialOutputDescription(
    _ contextId: NSNumber?,
    addressB64: String?,
    rcmB64: String?,
    eskB64: String?,
    value: NSNumber?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = preparePartialOutputDescriptionImpl(contextId, addressB64, rcmB64, eskB64, value)
    completion(r.0, r.1)
  }

  private static func preparePartialOutputDescriptionImpl(_ contextId: NSNumber?, _ addressB64: String?, _ rcmB64: String?, _ eskB64: String?, _ value: NSNumber?) -> (String?, String?) {
    guard let cid = contextId?.intValue, let ctx = contextStore[cid],
          let address = data(fromBase64: addressB64), let rcm = data(fromBase64: rcmB64),
          let esk = data(fromBase64: eskB64), let v = value?.uint64Value else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.preparePartialOutputDescription(with: ctx, to: address, withRcm: rcm, withEsk: esk, ofValue: v)), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  // MARK: - Payment Address

  @objc(getPaymentAddress:indexB64:completion:)
  public static func getPaymentAddress(
    _ viewingKeyB64: String?,
    indexB64: String?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = getPaymentAddressImpl(viewingKeyB64, indexB64)
    completion(r.0, r.1)
  }

  private static func getPaymentAddressImpl(_ viewingKeyB64: String?, _ indexB64: String?) -> (String?, String?) {
    guard let vk = data(fromBase64: viewingKeyB64) else { return (nil, "Invalid args") }
    do {
      let index: [UInt8]? = indexB64.flatMap { data(fromBase64: $0) }
      let address: [UInt8]
      if let idx = index, !idx.isEmpty {
        address = try sapling.getPaymentAddress(from: vk, at: idx)
      } else {
        let zeroIndex = [UInt8](repeating: 0, count: 11)
        address = try sapling.getPaymentAddress(from: vk, at: zeroIndex)
      }
      return (result(address), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  @objc(getNextPaymentAddress:indexB64:completion:)
  public static func getNextPaymentAddress(
    _ viewingKeyB64: String?,
    indexB64: String?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = getNextPaymentAddressImpl(viewingKeyB64, indexB64)
    completion(r.0, r.1)
  }

  private static func getNextPaymentAddressImpl(_ viewingKeyB64: String?, _ indexB64: String?) -> (String?, String?) {
    guard let vk = data(fromBase64: viewingKeyB64), let index = data(fromBase64: indexB64) else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.getNextPaymentAddress(from: vk, lastAt: index)), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  // TODO: Add getRawPaymentAddress when it is fixed for Android

  @objc(getDiversifierFromRawPaymentAddress:completion:)
  public static func getDiversifierFromRawPaymentAddress(
    _ addressB64: String?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = getDiversifierFromRawPaymentAddressImpl(addressB64)
    completion(r.0, r.1)
  }

  private static func getDiversifierFromRawPaymentAddressImpl(_ addressB64: String?) -> (String?, String?) {
    guard let address = data(fromBase64: addressB64) else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.getDiversifier(fromRaw: address)), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  // TODO: Add getPkdFromRawPaymentAddress when it is fixed for Android

  // MARK: - Proving Context

  @objc(initProvingContextWithCompletion:)
  public static func initProvingContext(completion: @escaping RNSaplingContextCompletion) {
    let r = initProvingContextImpl()
    completion(r.0, r.1)
  }

  private static func initProvingContextImpl() -> (NSNumber?, String?) {
    do {
      let ctx = try sapling.initProvingContext()
      lock.lock()
      nextContextId += 1
      let id = nextContextId
      contextStore[id] = ctx
      lock.unlock()
      return (NSNumber(value: id), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  @objc(dropProvingContext:completion:)
  public static func dropProvingContext(
    _ contextId: NSNumber?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = dropProvingContextImpl(contextId)
    completion(r.0, r.1)
  }

  private static func dropProvingContextImpl(_ contextId: NSNumber?) -> (String?, String?) {
    guard let cid = contextId?.intValue else { return (nil, "Invalid contextId") }
    lock.lock()
    if let ctx = contextStore.removeValue(forKey: cid) {
      sapling.dropProvingContext(ctx)
    }
    lock.unlock()
    return ("", nil)
  }

  // MARK: - Rand

  @objc(randRWithCompletion:)
  public static func randR(completion: @escaping RNSaplingStringCompletion) {
    let r = randRImpl()
    completion(r.0, r.1)
  }

  private static func randRImpl() -> (String?, String?) {
    do {
      return (result(try sapling.randR()), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  // MARK: - Signature

  @objc(createBindingSignature:balance:sighashB64:completion:)
  public static func createBindingSignature(
    _ contextId: NSNumber?,
    balance: NSNumber?,
    sighashB64: String?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = createBindingSignatureImpl(contextId, balance, sighashB64)
    completion(r.0, r.1)
  }

  private static func createBindingSignatureImpl(_ contextId: NSNumber?, _ balance: NSNumber?, _ sighashB64: String?) -> (String?, String?) {
    guard let cid = contextId?.intValue, let ctx = contextStore[cid],
          let balanceVal = balance?.int64Value, let sighash = data(fromBase64: sighashB64) else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.createBindingSignature(with: ctx, balance: balanceVal, sighash: sighash)), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  // MARK: - Spend Description

  @objc(prepareSpendDescriptionWithSpendingKey:spendingKeyB64:addressB64:rcmB64:arB64:value:anchorB64:merklePathB64:completion:)
  public static func prepareSpendDescriptionWithSpendingKey(
    _ contextId: NSNumber?,
    spendingKeyB64: String?,
    addressB64: String?,
    rcmB64: String?,
    arB64: String?,
    value: NSNumber?,
    anchorB64: String?,
    merklePathB64: String?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = prepareSpendDescriptionWithSpendingKeyImpl(contextId, spendingKeyB64, addressB64, rcmB64, arB64, value, anchorB64, merklePathB64)
    completion(r.0, r.1)
  }

  private static func prepareSpendDescriptionWithSpendingKeyImpl(
    _ contextId: NSNumber?,
    _ spendingKeyB64: String?,
    _ addressB64: String?,
    _ rcmB64: String?,
    _ arB64: String?,
    _ value: NSNumber?,
    _ anchorB64: String?,
    _ merklePathB64: String?
  ) -> (String?, String?) {
    guard let cid = contextId?.intValue, let ctx = contextStore[cid],
          let xsk = data(fromBase64: spendingKeyB64), let address = data(fromBase64: addressB64),
          let rcm = data(fromBase64: rcmB64), let ar = data(fromBase64: arB64),
          let v = value?.uint64Value, let anchor = data(fromBase64: anchorB64),
          let merklePath = data(fromBase64: merklePathB64) else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.prepareSpendDescriptionWithSpendingKey(with: ctx, using: xsk, to: address, withRcm: rcm, withAr: ar, ofValue: v, withAnchor: anchor, at: merklePath)), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  @objc(signSpendDescription:spendingKeyB64:arB64:sighashB64:completion:)
  public static func signSpendDescription(
    _ spendDescriptionB64: String?,
    spendingKeyB64: String?,
    arB64: String?,
    sighashB64: String?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = signSpendDescriptionImpl(spendDescriptionB64, spendingKeyB64, arB64, sighashB64)
    completion(r.0, r.1)
  }

  private static func signSpendDescriptionImpl(_ spendDescriptionB64: String?, _ spendingKeyB64: String?, _ arB64: String?, _ sighashB64: String?) -> (String?, String?) {
    guard let desc = data(fromBase64: spendDescriptionB64), let xsk = data(fromBase64: spendingKeyB64),
          let ar = data(fromBase64: arB64), let sighash = data(fromBase64: sighashB64) else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.signSpendDescription(desc, using: xsk, with: ar, sighash: sighash)), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  // MARK: - Spending Key

  @objc(getExtendedSpendingKey:derivationPath:completion:)
  public static func getExtendedSpendingKey(
    _ seedB64: String?,
    derivationPath: String?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = getExtendedSpendingKeyImpl(seedB64, derivationPath)
    completion(r.0, r.1)
  }

  private static func getExtendedSpendingKeyImpl(_ seedB64: String?, _ derivationPath: String?) -> (String?, String?) {
    guard let seed = data(fromBase64: seedB64), let path = derivationPath else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.getExtendedSpendingKey(from: seed, derivationPath: path)), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  // MARK: - Viewing Key

  @objc(getExtendedFullViewingKey:derivationPath:completion:)
  public static func getExtendedFullViewingKey(
    _ seedB64: String?,
    derivationPath: String?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = getExtendedFullViewingKeyImpl(seedB64, derivationPath)
    completion(r.0, r.1)
  }

  private static func getExtendedFullViewingKeyImpl(_ seedB64: String?, _ derivationPath: String?) -> (String?, String?) {
    guard let seed = data(fromBase64: seedB64), let path = derivationPath else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.getExtendedFullViewingKey(from: seed, derivationPath: path)), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  @objc(getExtendedFullViewingKeyFromSpendingKey:completion:)
  public static func getExtendedFullViewingKeyFromSpendingKey(
    _ spendingKeyB64: String?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = getExtendedFullViewingKeyFromSpendingKeyImpl(spendingKeyB64)
    completion(r.0, r.1)
  }

  private static func getExtendedFullViewingKeyFromSpendingKeyImpl(_ spendingKeyB64: String?) -> (String?, String?) {
    guard let xsk = data(fromBase64: spendingKeyB64) else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.getExtendedFullViewingKey(from: xsk)), nil)
    } catch { return (nil, error.localizedDescription) }
  }

  // TODO: Add getOutgoingViewingKey when it is fixed for Android

  @objc(getIncomingViewingKey:completion:)
  public static func getIncomingViewingKey(
    _ viewingKeyB64: String?,
    completion: @escaping RNSaplingStringCompletion
  ) {
    let r = getIncomingViewingKeyImpl(viewingKeyB64)
    completion(r.0, r.1)
  }

  private static func getIncomingViewingKeyImpl(_ viewingKeyB64: String?) -> (String?, String?) {
    guard let xfvk = data(fromBase64: viewingKeyB64) else { return (nil, "Invalid args") }
    do {
      return (result(try sapling.getIncomingViewingKey(from: xfvk)), nil)
    } catch { return (nil, error.localizedDescription) }
  }
}
