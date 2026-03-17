package com.madfish.sapling;

import android.util.Base64;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

/**
 * React Native bridge for airgap-sapling.
 *
 * All FFI calls are routed through {@link SaplingFix} which uses our own
 * JNI bridge (libsapling_fix.so) instead of the upstream one.  This fixes
 * wrong-symbol bugs, the missing deriveEpkFromEsk wrapper, and heap
 * corruption caused by mismatched new[]/delete in the upstream bridge.
 *
 * The proving-context pointer is passed through JS as a decimal string
 * (not a double) to avoid precision loss for MTE-tagged 64-bit pointers.
 */
public class SaplingModule extends ReactContextBaseJavaModule {

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

  private void ok(Callback cb, byte[] out, String errMsg) {
    if (out != null) {
      cb.invoke(null, toBase64(out));
    } else {
      String diag = SaplingFix.getUnresolvedSymbols();
      if (diag != null) {
        cb.invoke(errMsg + " [unresolved FFI symbols: " + diag + "]", null);
      } else {
        cb.invoke(errMsg + " [FFI returned null]", null);
      }
    }
  }

  // Authorizing Key
  @ReactMethod
  public void getProofAuthorizingKey(String spendingKeyB64, Callback callback) {
    try {
      ok(callback, SaplingFix.getProofAuthorizingKey(fromBase64(spendingKeyB64)),
         "Failed to derive proof authorizing key");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Commitment
  @ReactMethod
  public void verifyCommitment(String commitmentB64, String addressB64, double value, String rcmB64, Callback callback) {
    try {
      byte[] cmu = SaplingFix.computeCmu(fromBase64(addressB64), (long) value, fromBase64(rcmB64));
      if (cmu == null) {
        callback.invoke("Failed to compute commitment", null);
        return;
      }
      byte[] commitment = fromBase64(commitmentB64);
      boolean match = java.util.Arrays.equals(commitment, cmu);
      callback.invoke(null, match);
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Init
  @ReactMethod
  public void initParameters(String spendParametersB64, String outputParametersB64, Callback callback) {
    try {
      boolean ok = SaplingFix.initParameters(fromBase64(spendParametersB64), fromBase64(outputParametersB64));
      if (ok) {
        callback.invoke(null, null);
      } else {
        callback.invoke("Failed to initialize Sapling parameters", null);
      }
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Key Agreement
  @ReactMethod
  public void keyAgreement(String pB64, String skB64, Callback callback) {
    try {
      ok(callback, SaplingFix.keyAgreement(fromBase64(pB64), fromBase64(skB64)),
         "Failed to create key agreement");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Merkle Tree
  @ReactMethod
  public void merkleHash(double depth, String lhsB64, String rhsB64, Callback callback) {
    try {
      ok(callback, SaplingFix.merkleHash((long) depth, fromBase64(lhsB64), fromBase64(rhsB64)),
         "Failed to create Merkle hash");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Nullifier
  @ReactMethod
  public void computeNullifier(String viewingKeyB64, String addressB64, double value, String rcmB64, double position, Callback callback) {
    try {
      ok(callback,
         SaplingFix.computeNullifier(fromBase64(viewingKeyB64), fromBase64(addressB64),
                                     (long) value, fromBase64(rcmB64), (long) position),
         "Failed to compute nullifier");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Output Description
  @ReactMethod
  public void prepareOutputDescription(String contextId, String viewingKeyB64, String addressB64, String rcmB64, double value, Callback callback) {
    try {
      ok(callback,
         SaplingFix.prepareOutputDescription(parseCtx(contextId), fromBase64(viewingKeyB64),
                                             fromBase64(addressB64), fromBase64(rcmB64), (long) value),
         "Failed to prepare output description");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void preparePartialOutputDescription(String contextId, String addressB64, String rcmB64, String eskB64, double value, Callback callback) {
    try {
      ok(callback,
         SaplingFix.preparePartialOutputDescription(parseCtx(contextId), fromBase64(addressB64),
                                                    fromBase64(rcmB64), fromBase64(eskB64), (long) value),
         "Failed to prepare partial output description");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Payment Address
  @ReactMethod
  public void getPaymentAddress(String viewingKeyB64, String indexB64, Callback callback) {
    try {
      byte[] xfvk = fromBase64(viewingKeyB64);
      byte[] out;
      if (indexB64 == null || indexB64.isEmpty()) {
        out = SaplingFix.getDefaultPaymentAddress(xfvk);
      } else {
        out = SaplingFix.getPaymentAddressFromXfvk(xfvk, fromBase64(indexB64));
      }
      ok(callback, out, "Failed to create payment address");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void getNextPaymentAddress(String viewingKeyB64, String indexB64, Callback callback) {
    try {
      ok(callback,
         SaplingFix.getNextPaymentAddress(fromBase64(viewingKeyB64), fromBase64(indexB64)),
         "Failed to create next payment address");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void getRawPaymentAddress(String incomingViewingKeyB64, String diversifierB64, Callback callback) {
    try {
      ok(callback,
         SaplingFix.getRawPaymentAddressFromIvk(fromBase64(incomingViewingKeyB64), fromBase64(diversifierB64)),
         "Failed to create payment address from IVK");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void getDiversifierFromRawPaymentAddress(String addressB64, Callback callback) {
    try {
      ok(callback,
         SaplingFix.getDiversifierFromAddress(fromBase64(addressB64)),
         "Failed to extract diversifier from address");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void getPkdFromRawPaymentAddress(String addressB64, Callback callback) {
    try {
      ok(callback,
         SaplingFix.getPkdFromRawPaymentAddress(fromBase64(addressB64)),
         "Failed to extract pkd from address");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Proving Context
  @ReactMethod
  public void initProvingContext(Callback callback) {
    try {
      long contextId = SaplingFix.initProvingContext();
      callback.invoke(null, String.valueOf(contextId));
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void dropProvingContext(String contextId, Callback callback) {
    try {
      SaplingFix.dropProvingContext(parseCtx(contextId));
      callback.invoke(null, null);
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Rand
  @ReactMethod
  public void randR(Callback callback) {
    try {
      ok(callback, SaplingFix.randR(), "Failed to create random scalar");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Signature
  @ReactMethod
  public void createBindingSignature(String contextId, double balance, String sighashB64, Callback callback) {
    try {
      ok(callback,
         SaplingFix.createBindingSignature(parseCtx(contextId), (long) balance, fromBase64(sighashB64)),
         "Failed to create binding signature");
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
      ok(callback,
         SaplingFix.prepareSpendDescriptionFromXsk(
           parseCtx(contextId), fromBase64(spendingKeyB64), fromBase64(addressB64),
           fromBase64(rcmB64), fromBase64(arB64), (long) value,
           fromBase64(anchorB64), fromBase64(merklePathB64)),
         "Failed to prepare spend description");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void prepareSpendDescriptionWithAuthorizingKey(
    String contextId, String authorizingKeyB64, String addressB64, String rcmB64,
    String arB64, double value, String anchorB64, String merklePathB64, Callback callback
  ) {
    try {
      ok(callback,
         SaplingFix.prepareSpendDescriptionFromPak(
           parseCtx(contextId), fromBase64(authorizingKeyB64), fromBase64(addressB64),
           fromBase64(rcmB64), fromBase64(arB64), (long) value,
           fromBase64(anchorB64), fromBase64(merklePathB64)),
         "Failed to prepare spend description");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void signSpendDescription(String spendDescriptionB64, String spendingKeyB64, String arB64, String sighashB64, Callback callback) {
    try {
      ok(callback,
         SaplingFix.signSpendDescription(fromBase64(spendDescriptionB64), fromBase64(spendingKeyB64),
                                         fromBase64(arB64), fromBase64(sighashB64)),
         "Failed to sign spend description");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Spending Key
  @ReactMethod
  public void getExtendedSpendingKey(String seedB64, String derivationPath, Callback callback) {
    try {
      ok(callback,
         SaplingFix.getExtendedSpendingKey(fromBase64(seedB64), derivationPath),
         "Failed to create extended spending key");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // Viewing Key
  @ReactMethod
  public void getExtendedFullViewingKey(String seedB64, String derivationPath, Callback callback) {
    try {
      ok(callback,
         SaplingFix.getExtendedFullViewingKey(fromBase64(seedB64), derivationPath),
         "Failed to create extended full viewing key");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void getExtendedFullViewingKeyFromSpendingKey(String spendingKeyB64, Callback callback) {
    try {
      ok(callback,
         SaplingFix.getExtendedFullViewingKeyFromXsk(fromBase64(spendingKeyB64)),
         "Failed to derive full viewing key from spending key");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void getOutgoingViewingKey(String viewingKeyB64, Callback callback) {
    try {
      ok(callback,
         SaplingFix.getOutgoingViewingKey(fromBase64(viewingKeyB64)),
         "Failed to derive outgoing viewing key");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  @ReactMethod
  public void getIncomingViewingKey(String viewingKeyB64, Callback callback) {
    try {
      ok(callback,
         SaplingFix.getIncomingViewingKey(fromBase64(viewingKeyB64)),
         "Failed to derive incoming viewing key");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }

  // EPK Derivation
  @ReactMethod
  public void deriveEpkFromEsk(String diversifierB64, String eskB64, Callback callback) {
    try {
      ok(callback,
         SaplingFix.deriveEpkFromEsk(fromBase64(diversifierB64), fromBase64(eskB64)),
         "Failed to derive EPK from ESK");
    } catch (Exception e) {
      callback.invoke(e.getMessage(), null);
    }
  }
}
