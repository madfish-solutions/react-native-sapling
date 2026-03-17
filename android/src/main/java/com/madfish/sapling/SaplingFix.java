package com.madfish.sapling;

import java.util.Arrays;

/**
 * Complete bypass of the upstream airgap-sapling JNI bridge.
 *
 * Every FFI call is routed through our own libsapling_fix.so, which resolves
 * the correct symbols from the already-loaded libsapling.so via dlsym.
 * This avoids:
 *   1. Three wrong-symbol bugs (ovk, pkd, ivk→address).
 *   2. The missing public wrapper for deriveEpkFromEsk.
 *   3. Heap corruption from local_clean() using scalar delete on new[] buffers.
 */
public class SaplingFix {

    private static boolean nativeLoaded = false;
    private static String unresolvedSymbols = null;

    private static synchronized void ensureNativeLoaded() {
        if (!nativeLoaded) {
            System.loadLibrary("sapling");
            System.loadLibrary("sapling_fix");
            nativeLoaded = true;
            unresolvedSymbols = nativeUnresolvedSymbols();
        }
    }

    /**
     * Returns a non-empty string describing unresolved FFI symbols,
     * or null if everything resolved correctly.
     */
    public static String getUnresolvedSymbols() {
        ensureNativeLoaded();
        return (unresolvedSymbols != null && !unresolvedSymbols.isEmpty())
                ? unresolvedSymbols : null;
    }

    // XFVK serialisation layout (zcash_primitives):
    //   depth(1) | parent_fvk_tag(4) | child_index(4) | chain_code(32)
    //   | ak(32) | nk(32) | ovk(32)
    // Total = 137 bytes.  OVK starts at offset 105.
    private static final int XFVK_OVK_OFFSET = 105;
    private static final int OVK_LENGTH = 32;
    private static final int XFVK_MIN_LENGTH = XFVK_OVK_OFFSET + OVK_LENGTH;

    // Raw Sapling payment address layout:
    //   diversifier(11) | pkd(32)
    // Total = 43 bytes.  PKD starts at offset 11.
    private static final int DIVERSIFIER_LENGTH = 11;
    private static final int PKD_LENGTH = 32;
    private static final int ADDRESS_MIN_LENGTH = DIVERSIFIER_LENGTH + PKD_LENGTH;

    /** Extract the 32-byte OVK from a serialised XFVK (pure Java). */
    public static byte[] getOutgoingViewingKey(byte[] xfvk) {
        if (xfvk == null || xfvk.length < XFVK_MIN_LENGTH) return null;
        return Arrays.copyOfRange(xfvk, XFVK_OVK_OFFSET, XFVK_OVK_OFFSET + OVK_LENGTH);
    }

    /** Extract the 32-byte PKD from a raw payment address (pure Java). */
    public static byte[] getPkdFromRawPaymentAddress(byte[] address) {
        if (address == null || address.length < ADDRESS_MIN_LENGTH) return null;
        return Arrays.copyOfRange(address, DIVERSIFIER_LENGTH, DIVERSIFIER_LENGTH + PKD_LENGTH);
    }

    // ---- All remaining methods go through our native bridge ----

    public static byte[] getProofAuthorizingKey(byte[] xsk) {
        ensureNativeLoaded();
        return nativePakFromXsk(xsk);
    }

    public static byte[] computeCmu(byte[] address, long value, byte[] rcm) {
        ensureNativeLoaded();
        return nativeComputeCmu(address, value, rcm);
    }

    public static boolean initParameters(byte[] spend, byte[] output) {
        ensureNativeLoaded();
        return nativeInitParams(spend, output);
    }

    public static byte[] keyAgreement(byte[] p, byte[] sk) {
        ensureNativeLoaded();
        return nativeKeyAgreement(p, sk);
    }

    public static byte[] merkleHash(long depth, byte[] lhs, byte[] rhs) {
        ensureNativeLoaded();
        return nativeMerkleHash(depth, lhs, rhs);
    }

    public static byte[] computeNullifier(byte[] xfvk, byte[] address, long value, byte[] rcm, long position) {
        ensureNativeLoaded();
        return nativeComputeNullifier(xfvk, address, value, rcm, position);
    }

    public static byte[] prepareOutputDescription(long ctx, byte[] xfvk, byte[] address, byte[] rcm, long value) {
        ensureNativeLoaded();
        return nativeOutputDescFromXfvk(ctx, xfvk, address, rcm, value);
    }

    public static byte[] preparePartialOutputDescription(long ctx, byte[] address, byte[] rcm, byte[] esk, long value) {
        ensureNativeLoaded();
        return nativePartialOutputDesc(ctx, address, rcm, esk, value);
    }

    public static byte[] deriveEpkFromEsk(byte[] diversifier, byte[] esk) {
        ensureNativeLoaded();
        return nativeDeriveEpkFromEsk(diversifier, esk);
    }

    public static byte[] getPaymentAddressFromXfvk(byte[] xfvk, byte[] index) {
        ensureNativeLoaded();
        return nativePaymentAddressFromXfvk(xfvk, index);
    }

    public static byte[] getNextPaymentAddress(byte[] xfvk, byte[] index) {
        ensureNativeLoaded();
        return nativeNextPaymentAddress(xfvk, index);
    }

    public static byte[] getRawPaymentAddressFromIvk(byte[] ivk, byte[] diversifier) {
        ensureNativeLoaded();
        return nativePaymentAddressFromIvk(ivk, diversifier);
    }

    public static byte[] getDefaultPaymentAddress(byte[] xfvk) {
        ensureNativeLoaded();
        return nativeDefaultPaymentAddr(xfvk);
    }

    public static byte[] getDiversifierFromAddress(byte[] address) {
        ensureNativeLoaded();
        return nativeDiversifierFromAddr(address);
    }

    public static long initProvingContext() {
        ensureNativeLoaded();
        return nativeInitProvingContext();
    }

    public static void dropProvingContext(long ctx) {
        ensureNativeLoaded();
        nativeDropProvingContext(ctx);
    }

    public static byte[] randR() {
        ensureNativeLoaded();
        return nativeRandR();
    }

    public static byte[] createBindingSignature(long ctx, long balance, byte[] sighash) {
        ensureNativeLoaded();
        return nativeBindingSignature(ctx, balance, sighash);
    }

    public static byte[] prepareSpendDescriptionFromXsk(
            long ctx, byte[] xsk, byte[] address, byte[] rcm,
            byte[] ar, long value, byte[] anchor, byte[] merklePath) {
        ensureNativeLoaded();
        return nativeSpendDescFromXsk(ctx, xsk, address, rcm, ar, value, anchor, merklePath);
    }

    public static byte[] prepareSpendDescriptionFromPak(
            long ctx, byte[] pak, byte[] address, byte[] rcm,
            byte[] ar, long value, byte[] anchor, byte[] merklePath) {
        ensureNativeLoaded();
        return nativeSpendDescFromPak(ctx, pak, address, rcm, ar, value, anchor, merklePath);
    }

    public static byte[] signSpendDescription(byte[] desc, byte[] xsk, byte[] ar, byte[] sighash) {
        ensureNativeLoaded();
        return nativeSignSpendDesc(desc, xsk, ar, sighash);
    }

    public static byte[] getExtendedSpendingKey(byte[] seed, String derivationPath) {
        ensureNativeLoaded();
        return nativeXsk(seed, derivationPath);
    }

    public static byte[] getExtendedFullViewingKey(byte[] seed, String derivationPath) {
        ensureNativeLoaded();
        return nativeXfvk(seed, derivationPath);
    }

    public static byte[] getExtendedFullViewingKeyFromXsk(byte[] xsk) {
        ensureNativeLoaded();
        return nativeXfvkFromXsk(xsk);
    }

    public static byte[] getIncomingViewingKey(byte[] xfvk) {
        ensureNativeLoaded();
        return nativeXfvkToIvk(xfvk);
    }

    // ---- native declarations ----

    private static native byte[] nativePakFromXsk(byte[] xsk);
    private static native byte[] nativeComputeCmu(byte[] address, long value, byte[] rcm);
    private static native boolean nativeInitParams(byte[] spend, byte[] output);
    private static native byte[] nativeKeyAgreement(byte[] p, byte[] sk);
    private static native byte[] nativeMerkleHash(long depth, byte[] lhs, byte[] rhs);
    private static native byte[] nativeComputeNullifier(byte[] xfvk, byte[] address, long value, byte[] rcm, long position);
    private static native byte[] nativeOutputDescFromXfvk(long ctx, byte[] xfvk, byte[] address, byte[] rcm, long value);
    private static native byte[] nativePartialOutputDesc(long ctx, byte[] address, byte[] rcm, byte[] esk, long value);
    private static native byte[] nativeDeriveEpkFromEsk(byte[] diversifier, byte[] esk);
    private static native byte[] nativePaymentAddressFromXfvk(byte[] xfvk, byte[] index);
    private static native byte[] nativeNextPaymentAddress(byte[] xfvk, byte[] index);
    private static native byte[] nativePaymentAddressFromIvk(byte[] ivk, byte[] diversifier);
    private static native byte[] nativeDefaultPaymentAddr(byte[] xfvk);
    private static native byte[] nativeDiversifierFromAddr(byte[] address);
    private static native long nativeInitProvingContext();
    private static native void nativeDropProvingContext(long ctx);
    private static native byte[] nativeRandR();
    private static native byte[] nativeBindingSignature(long ctx, long balance, byte[] sighash);
    private static native byte[] nativeSpendDescFromXsk(long ctx, byte[] xsk, byte[] address, byte[] rcm, byte[] ar, long value, byte[] anchor, byte[] merklePath);
    private static native byte[] nativeSpendDescFromPak(long ctx, byte[] pak, byte[] address, byte[] rcm, byte[] ar, long value, byte[] anchor, byte[] merklePath);
    private static native byte[] nativeSignSpendDesc(byte[] desc, byte[] xsk, byte[] ar, byte[] sighash);
    private static native byte[] nativeXsk(byte[] seed, String derivationPath);
    private static native byte[] nativeXfvk(byte[] seed, String derivationPath);
    private static native byte[] nativeXfvkFromXsk(byte[] xsk);
    private static native byte[] nativeXfvkToIvk(byte[] xfvk);
    private static native String nativeUnresolvedSymbols();
}
