package com.madfish.sapling;

import android.util.Base64;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import it.airgap.sapling.Sapling;

/**
 * React Native bridge for airgap-sapling.
 *
 * All FFI calls are routed through the upstream {@link Sapling} class from the
 * airgap-sapling 0.0.7-android-16kb AAR.  Functions absent from the upstream
 * public API (getProofAuthorizingKey, prepareSpendDescriptionWithAuthorizingKey,
 * deriveEpkFromEsk) are not exposed here and must be handled in the parent
 * project via WebView.
 *
 * The proving-context pointer is passed through JS as a decimal string
 * (not a double) to avoid precision loss for MTE-tagged 64-bit pointers.
 */
public class SaplingModule extends ReactContextBaseJavaModule {

  private static final Sapling sapling = new Sapling();

  public SaplingModule(ReactApplicationContext reactContext) {
    super(reactContext);
  }

  @Override
  public String getName() {
    return "RNSapling";
  }

  private static byte[] fromBase64(String b64) {
    return b64 == null ? null : Base64.decode(b64, Base64.NO_WRAP);
  }

  private static String toBase64(byte[] bytes) {
    return bytes == null ? null : Base64.encodeToString(bytes, Base64.NO_WRAP);
  }

  private static long parseCtx(String s) {
    return Long.parseLong(s);
  }

  // Commitment
  @ReactMethod
  public void verifyCommitment(String commitmentB64, String addressB64, double value, String rcmB64, Callback callback) {
    try {
      boolean match = sapling.verifyCommitment(fromBase64(commitmentB64), fromBase64(addressB64), (long) value, fromBase64(rcmB64));
      callback.invoke(null, match);
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Init
  @ReactMethod
  public void initParameters(String spendParametersB64, String outputParametersB64, Callback callback) {
    try {
      sapling.initParameters(fromBase64(spendParametersB64), fromBase64(outputParametersB64));
      callback.invoke(null, null);
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // TODO: Add keyAgreement when it is fixed for Android

  // Merkle Tree
  @ReactMethod
  public void merkleHash(double depth, String lhsB64, String rhsB64, Callback callback) {
    try {
      callback.invoke(null, toBase64(sapling.merkleHash((long) depth, fromBase64(lhsB64), fromBase64(rhsB64))));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Nullifier
  @ReactMethod
  public void computeNullifier(String viewingKeyB64, String addressB64, double value, String rcmB64, double position, Callback callback) {
    try {
      callback.invoke(null, toBase64(sapling.computeNullifier(
          fromBase64(viewingKeyB64), fromBase64(addressB64),
          (long) value, fromBase64(rcmB64), (long) position)));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Output Description
  @ReactMethod
  public void prepareOutputDescription(String contextId, String viewingKeyB64, String addressB64, String rcmB64, double value, Callback callback) {
    try {
      callback.invoke(null, toBase64(sapling.prepareOutputDescription(
          parseCtx(contextId), fromBase64(viewingKeyB64),
          fromBase64(addressB64), fromBase64(rcmB64), (long) value)));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void preparePartialOutputDescription(String contextId, String addressB64, String rcmB64, String eskB64, double value, Callback callback) {
    try {
      callback.invoke(null, toBase64(sapling.preparePartialOutputDescription(
          parseCtx(contextId), fromBase64(addressB64),
          fromBase64(rcmB64), fromBase64(eskB64), (long) value)));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Payment Address
  @ReactMethod
  public void getPaymentAddress(String viewingKeyB64, String indexB64, Callback callback) {
    try {
      byte[] index = (indexB64 == null || indexB64.isEmpty()) ? null : fromBase64(indexB64);
      callback.invoke(null, toBase64(sapling.getPaymentAddressFromViewingKey(fromBase64(viewingKeyB64), index)));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void getNextPaymentAddress(String viewingKeyB64, String indexB64, Callback callback) {
    try {
      callback.invoke(null, toBase64(sapling.getNextPaymentAddressFromViewingKey(fromBase64(viewingKeyB64), fromBase64(indexB64))));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // TODO: Add getRawPaymentAddress when it is fixed for Android

  @ReactMethod
  public void getDiversifierFromRawPaymentAddress(String addressB64, Callback callback) {
    try {
      callback.invoke(null, toBase64(sapling.getDiversifierFromRawPaymentAddress(fromBase64(addressB64))));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // TODO: Add getPkdFromRawPaymentAddress when it is fixed for Android

  // Proving Context
  @ReactMethod
  public void initProvingContext(Callback callback) {
    try {
      long contextId = sapling.initProvingContext();
      callback.invoke(null, String.valueOf(contextId));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void dropProvingContext(String contextId, Callback callback) {
    try {
      sapling.dropProvingContext(parseCtx(contextId));
      callback.invoke(null, null);
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Rand
  @ReactMethod
  public void randR(Callback callback) {
    try {
      callback.invoke(null, toBase64(sapling.randR()));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Signature
  @ReactMethod
  public void createBindingSignature(String contextId, double balance, String sighashB64, Callback callback) {
    try {
      callback.invoke(null, toBase64(sapling.createBindingSignature(parseCtx(contextId), (long) balance, fromBase64(sighashB64))));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Spend Description
  @ReactMethod
  public void prepareSpendDescriptionWithSpendingKey(
    String contextId, String spendingKeyB64, String addressB64, String rcmB64,
    String arB64, double value, String anchorB64, String merklePathB64, Callback callback
  ) {
    try {
      callback.invoke(null, toBase64(sapling.prepareSpendDescription(
          parseCtx(contextId), fromBase64(spendingKeyB64), fromBase64(addressB64),
          fromBase64(rcmB64), fromBase64(arB64), (long) value,
          fromBase64(anchorB64), fromBase64(merklePathB64))));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void signSpendDescription(String spendDescriptionB64, String spendingKeyB64, String arB64, String sighashB64, Callback callback) {
    try {
      callback.invoke(null, toBase64(sapling.signSpendDescription(
          fromBase64(spendDescriptionB64), fromBase64(spendingKeyB64),
          fromBase64(arB64), fromBase64(sighashB64))));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Spending Key
  @ReactMethod
  public void getExtendedSpendingKey(String seedB64, String derivationPath, Callback callback) {
    try {
      callback.invoke(null, toBase64(sapling.getExtendedSpendingKey(fromBase64(seedB64), derivationPath)));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Viewing Key
  @ReactMethod
  public void getExtendedFullViewingKey(String seedB64, String derivationPath, Callback callback) {
    try {
      callback.invoke(null, toBase64(sapling.getExtendedFullViewingKey(fromBase64(seedB64), derivationPath)));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void getExtendedFullViewingKeyFromSpendingKey(String spendingKeyB64, Callback callback) {
    try {
      callback.invoke(null, toBase64(sapling.getExtendedFullViewingKeyFromSpendingKey(fromBase64(spendingKeyB64))));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // TODO: Add getOutgoingViewingKey when it is fixed for Android

  @ReactMethod
  public void getIncomingViewingKey(String viewingKeyB64, Callback callback) {
    try {
      callback.invoke(null, toBase64(sapling.getIncomingViewingKey(fromBase64(viewingKeyB64))));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }
}
