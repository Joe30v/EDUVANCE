// Simple in-memory OTP state for the current app session.
// Keyed by Firebase UID -> OTP code string.

final Map<String, String> pendingOtps = {};
final Set<String> pendingOtpShown = {};

void setPendingOTP(String uid, String code) {
  pendingOtps[uid] = code;
  pendingOtpShown.remove(uid);
}

void clearPendingOTP(String uid) {
  pendingOtps.remove(uid);
  pendingOtpShown.remove(uid);
}

String? getPendingOTPForUid(String uid) => pendingOtps[uid];

void markPendingOTPShown(String uid) {
  pendingOtpShown.add(uid);
}

bool isPendingOTPShown(String uid) => pendingOtpShown.contains(uid);
